const slides = document.querySelectorAll("#slides img");
const thumbnails = document.querySelectorAll("#thumbnails button");
let current = 0;

function selectSlide(index) {
    slides[current].hidden = true;
    thumbnails[current].removeAttribute("aria-current");

    current = (index + slides.length) % slides.length;
    slides[current].hidden = false;
    thumbnails[current].setAttribute("aria-current", "true");
    thumbnails[current].scrollIntoView({ block: "nearest", inline: "nearest" });
}

document.querySelector("#slide_left").addEventListener("click", () => selectSlide(current - 1));
document.querySelector("#slide_right").addEventListener("click", () => selectSlide(current + 1));
thumbnails.forEach((thumbnail, index) => {
    thumbnail.addEventListener("click", () => selectSlide(index));
});
