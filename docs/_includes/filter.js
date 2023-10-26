function filterCount(n) {
  Array.from(document.querySelectorAll('.books .book')).forEach(book => {
    if (Number(book.dataset.count) > Number(n)) {
      book.hidden = false
    } else {
      book.hidden = true
    }
  })
  document.querySelector("#filter-range").value = n
  document.querySelector("#filter-value").value = n
}

document.querySelector("#filter-range").addEventListener('mouseup', function (ev) {
  filterCount(ev.target.value)
})

document.querySelector("#filter-value").addEventListener('change', function (ev) {
  filterCount(ev.target.value)
})

if (urlquery().min) {
  filterCount(urlquery().min)
} else {
  filterCount(1)
}
