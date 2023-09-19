function filterCount(n) {
  const num = typeof n === "object" ? n.target.value : n
  $$(".books .book").forEach((book) => {
    if (Number(book.dataset.count) > Number(num)) {
      book.hidden = false
    } else {
      book.hidden = true
    }
  })
  $("#filter-range").value = num
  $("#filter-value").value = num
}

$("#filter-range").addEventListener("mouseup", filterCount)
$("#filter-value").addEventListener("change", filterCount)

if (urlquery().min) {
  filterCount(urlquery().min)
} else {
  filterCount(1)
}
