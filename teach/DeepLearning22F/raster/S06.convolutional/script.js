let leftArrow = document.querySelector("#slide_left");
let rightArrow = document.querySelector("#slide_right");
let slidesContainer = document.querySelector("#slides");

let applyThumbnail = function (dataIdx) {
    document.querySelector("#thumbnails img.active").classList.remove("active");
    document
        .querySelector(`#thumbnails [data-index='${parseInt(dataIdx)}']`)
        .classList.add("active");
};

let thumbnailClick = function (dataIdx) {
    document.querySelector("#thumbnails img.active").classList.remove("active");
    document
        .querySelector(`#thumbnails [data-index='${parseInt(dataIdx)}']`)
        .classList.add("active");
    document.querySelector(`#slides > img.active`).classList.remove("active");
    document
        .querySelector(`#slides > [data-index='${parseInt(dataIdx)}']`)
        .classList.add("active");
};

leftArrow.addEventListener("click", function () {
    const currentActive = document.querySelector("#slides > img.active");
    const prevSibling = currentActive.previousElementSibling;
    currentActive.classList.remove("active");
    if (prevSibling) {
        prevSibling.classList.add("active");
        applyThumbnail(prevSibling.getAttribute("data-index"));
    } else {
        const last = document.querySelector("#slides > :last-child");
        last.classList.add("active");
        applyThumbnail(last.getAttribute("data-index"));
    }
});

rightArrow.addEventListener("click", function () {
    const currentActive = document.querySelector("#slides > img.active");
    const nextSibling = currentActive.nextElementSibling;
    currentActive.classList.remove("active");
    if (nextSibling) {
        nextSibling.classList.add("active");
        applyThumbnail(nextSibling.getAttribute("data-index"));
    } else {
        const first = document.querySelector("#slides > :first-child");
        first.classList.add("active");
        applyThumbnail(first.getAttribute("data-index"));
    }
});

document.querySelectorAll(".thumbnail").forEach(function (elem) {
    elem.addEventListener("click", function () {
        thumbnailClick(this.getAttribute("data-index"));
    });
});