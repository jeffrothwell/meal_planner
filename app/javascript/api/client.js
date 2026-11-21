function csrfMeta() {
  return document.querySelector('meta[name="csrf-token"]')
}

function csrfToken() {
  return csrfMeta()?.content
}

// The token baked into the page goes stale if a tab is restored after its session
// cookie is gone (common on mobile browsers). Loading any HTML page makes Rails
// issue a fresh session cookie and token, so fetch one and swap the token in.
async function refreshCsrfToken() {
  const response = await fetch('/', { headers: { 'Accept': 'text/html' } })
  if (!response.ok) return false

  const html  = await response.text()
  const token = new DOMParser()
    .parseFromString(html, 'text/html')
    .querySelector('meta[name="csrf-token"]')?.content
  if (!token) return false

  csrfMeta()?.setAttribute('content', token)
  return true
}

function send(path, { method, body }) {
  return fetch(path, {
    method,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })
}

async function request(path, { method = 'GET', body } = {}) {
  let response = await send(path, { method, body })
  let data     = response.ok ? null : await response.json().catch(() => ({}))

  // A CSRF rejection is a 422 with an empty body; real validation failures are 422s
  // that carry `error` / `errors`. On a CSRF rejection, refresh the token and retry once.
  const csrfRejected = response.status === 422 && !data.error && !data.errors
  if (csrfRejected && await refreshCsrfToken()) {
    response = await send(path, { method, body })
    data     = response.ok ? null : await response.json().catch(() => ({}))
  }

  if (!response.ok) {
    // errors is an object keyed by field name — flatten to a single summary message
    const summary = data.error
      || Object.values(data.errors || {}).flat().join(', ')
      || response.statusText
    const error = new Error(summary)
    error.status = response.status
    error.data   = data
    throw error
  }

  return response.json()
}

export const get   = (path)        => request(path)
export const post  = (path, body)  => request(path, { method: 'POST',  body })
export const patch = (path, body)  => request(path, { method: 'PATCH', body })
