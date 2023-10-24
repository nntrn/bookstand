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

function sortElements(url = location.search) {
  const search = Object.fromEntries([...new URLSearchParams(url).entries()])
  const sortkey = search.sort
  const fnkey = sort.map[sortkey]
  const sortParent = document.querySelector(`[data-${sortkey}]`).parentElement
  Array.from(sortParent.children)
    .sort((a, b) => sort[fnkey](a.dataset[sortkey], b.dataset[sortkey]))
    .forEach((node) => {
      sortParent.appendChild(node)
      node.querySelector(".sort-label").dataset.after = prettyDate(node.dataset[sortkey])
    })
  sortParent.dataset.sort = sortkey
}

document.querySelector("#sort-by").addEventListener('change', function (e) {
  sortElements(`?sort=${e.target.value}`)
})

if (location.search) {
  sortElements()
}
