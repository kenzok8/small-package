
    // const isDark = localStorage.getItem("isDark");
    // if (isDark == 1) {
    //   const element = document.querySelector("body");
    //   element.classList.add("dark");
    // }
    // const themetoggler = document.querySelector(".themetoggler");
    // themetoggler.addEventListener(
    //   "click",
    //   function (e) {
    //     e.preventDefault();
    //     const element = document.querySelector("body");
    //     element.classList.toggle("dark");
  
    //     const isDark = localStorage.getItem("isDark");
    //     localStorage.setItem("isDark", isDark == 1 ? 0 : 1);
    //   },
    //   false
    // );

function pdopenbar() {
    document.getElementById("header-bar-left").style.width = "300px";
    document.getElementById("header-bar-left").style.display = "block";
    document.getElementById("header-bar-right").style.width = "0";
    document.getElementById("header-bar-right").style.display = "none"
}

function pdclosebar() {
    document.getElementById("header-bar-left").style.display = "none";
    document.getElementById("header-bar-left").style.width = "0";
    document.getElementById("header-bar-right").style.display = "block";
    document.getElementById("header-bar-right").style.width = "50px"
}
