var prevScroll = window.scrollY || document.documentElement.scrollTop
var curScroll
var direction = 0
var prevDirection = 0
var header = document.querySelector("header")

window.prevPosition = window.scrollY || document.documentElement.scrollTop
var checkScroll = function () {
  curScroll = window.scrollY || document.documentElement.scrollTop
  if (curScroll > prevScroll) {
    direction = 2
  } else if (curScroll < prevScroll) {
    direction = 1
  }
  if (direction !== prevDirection) {
    toggleHeader(direction, curScroll)
  }
  prevScroll = curScroll
  console.log(prevScroll)
}

var toggleHeader = function (direction, curScroll) {
  if (direction === 2 && curScroll > 52) {
    header.classList.add("is-scrolling")
    prevDirection = direction
  } else if (direction === 1) {
    header.classList.remove("is-scrolling")
    prevDirection = direction
  }
}

window.addEventListener("scroll", function (e) {
  setTimeout(checkScroll, 500)
})
