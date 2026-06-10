function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

async function request(path, { method = 'GET', body } = {}) {
  const response = await fetch(path, {
    method,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  if (!response.ok) {
    const data = await response.json().catch(() => ({}))
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
