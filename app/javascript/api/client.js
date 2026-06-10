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
    const error = new Error(data.error || data.errors?.join(', ') || response.statusText)
    error.status = response.status
    error.data   = data
    throw error
  }

  return response.json()
}

export const get   = (path)        => request(path)
export const post  = (path, body)  => request(path, { method: 'POST',  body })
export const patch = (path, body)  => request(path, { method: 'PATCH', body })
