const sort = {
  number: (a, b) => (Number(a) > Number(b) ? -1 : 1),
  date: (a, b) => (new Date(a) > new Date(b) ? -1 : 1),
  text: (a, b) => (a.toLowerCase() > b.toLowerCase() ? -1 : 1),
}

function prettyDate(dt) {
  if (/[0-9]{4}-[0-9]{2}-[0-9]{2}/.test(dt)) {
    return (new Date(dt))
      .toLocaleDateString('en-us', { year: "numeric", month: "short", day: "numeric" })
      .toUpperCase()
  }
  return dt
}

function sortElements(search = urlquery().sort) {
  const sortType = $(`#sort-by [value=${search}]`).dataset.type
  const sortParent = $(`[data-${search}]`).parentElement
  Array.from(sortParent.children)
    .sort((a, b) => sort[sortType](a.dataset[search], b.dataset[search]))
    .forEach((node) => {
      sortParent.appendChild(node)
      node.querySelector(".sort-label").dataset.after = prettyDate(node.dataset[search])
    })
  sortParent.dataset.sort = search
}

$("#sort-by").addEventListener('change', function (e) {
  sortElements(e.target.value)
  replaceLocation({ sort: e.target.value })
})

if (urlquery().sort) {
  sortElements()
}
