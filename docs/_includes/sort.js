const sort = {
  number: (a, b) => (Number(a) > Number(b) ? -1 : 1),
  date: (a, b) => (new Date(a) > new Date(b) ? -1 : 1),
  text: (a, b) => (a.toLowerCase() > b.toLowerCase() ? -1 : 1),

  map: {
    created: "date",
    updated: "date",
    count: "number"
  }
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

  const fnkey = sort.map[search]
  const sortParent = document.querySelector(`[data-${search}]`).parentElement
  Array.from(sortParent.children)
    .sort((a, b) => sort[fnkey](a.dataset[search], b.dataset[search]))
    .forEach((node) => {
      sortParent.appendChild(node)
      node.querySelector(".sort-label").dataset.after = prettyDate(node.dataset[search])
    })
  sortParent.dataset.sort = search
}

document.querySelector("#sort-by").addEventListener('change', function (e) {
  sortElements(e.target.value)
})

if (urlquery().sort) {
  sortElements()
}
