const sort = {
  number: (a, b) => (Number(a) > Number(b) ? -1 : 1),
  date: (a, b) => (new Date(a) > new Date(b) ? -1 : 1),
  text: (a, b) => (a.toLowerCase() > b.toLowerCase() ? -1 : 1),

  map: {
    created: "date",
    modified: "date",
    count: "number"
  }
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
      node.querySelector(".sort-label").dataset.after = node.dataset[sortkey]
    })
  sortParent.dataset.sort = sortkey
}
