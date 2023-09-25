function hideHeader() {
  const header = document.querySelector("header")
  if (header.classList.contains('collapse')) {
    header.classList.remove("collapse")
  } else {
    header.classList.add("collapse")
  }
}

const btn = document.querySelector("#open-header")
btn.addEventListener("click", hideHeader)
