const $ = query => document.querySelector(query)
const $$ = query => Array.from(document.querySelectorAll(query))

const urlquery = (query = location.search) => Object.fromEntries(query.split(/[?&]/).filter(Boolean).map(e => e.split("=")));
const urlparse = obj => '?' + Object.entries(obj).map(e => `${e[0]}=${e[1]}`).join("&")

const sort = {
  number: (a, b) => (Number(a) > Number(b) ? -1 : 1),
  date: (a, b) => (new Date(a) > new Date(b) ? -1 : 1),
  text: (a, b) => (a.toLowerCase() > b.toLowerCase() ? -1 : 1)
}

function prettyDate(dt) {
  if (/[0-9]{4}-[0-9]{2}-[0-9]{2}/.test(dt)) {
    return new Date(`${dt.replace(/Z$/, '')}-06:00`).toLocaleDateString("en-us", { year: "numeric", month: "short", day: "numeric" }).toUpperCase()
  }
  return dt
}

function sortElements(search = urlquery().sort) {
  const sortType = $(`#sortby [value=${search}]`).dataset.type
  const sortParent = $(`[data-${search}]`).parentElement
  Array.from(sortParent.children)
    .sort((a, b) => sort[sortType](a.dataset[search], b.dataset[search]))
    .forEach((node) => {
      sortParent.appendChild(node)
    })
  sortParent.dataset.sort = search
}

function filterCount(n) {
  const num = !n ? 1 : typeof n === "object" ? n.target.value : n

  $$(".books .book").forEach((book) => {
    if (Number(book.dataset.count) > Number(num)) {
      book.hidden = false
    } else {
      book.hidden = true
    }
  })
  $("#rangefilter").value = num
  $("#numfilter").value = num
}

if (location.search) {
  const { min, sort } = urlquery()
  if (min) {
    filterCount(min)
  }

  if (sort) {
    sortElements()
    var index = $(`#sortby [value=${sort}]`).index
    $("#sortby").options.selectedIndex = index
  }
} else {
  filterCount()
}
