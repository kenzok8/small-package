/*
 *  luci-theme-kucat
 *  Copyright (C) 2019-2024 The Sirpdboy Team <herboy2008@gmail.com> 
 *
 *  Have a bug? Please create an issue here on GitHub!
 *      https://github.com/sirpdboy/luci-theme-kucat/issues
 *
 *  Licensed to the public under the Apache License 2.0
 */
function pdopenbar() {
    document.getElementById("header-bar-left").style.width = "300px";
    document.getElementById("header-bar-left").style.display = "block";
    document.getElementById("header-bar-right").style.width = "0";
    document.getElementById("header-bar-right").style.display = "none";
}

function pdclosebar() {
    document.getElementById("header-bar-left").style.display = "none";
    document.getElementById("header-bar-left").style.width = "0";
    document.getElementById("header-bar-right").style.display = "block";
    document.getElementById("header-bar-right").style.width = "50px";
}

function initScrollContainers() {
    document.querySelectorAll('.cbi-section, .mainmenu').forEach(section => {
        const content = section.querySelector('.content');
        if (!content) return;

        const checkOverflow = () => {
            section.classList.toggle(
                'auto-scroll-container',
                content.scrollHeight > section.clientHeight
            );
        };

        checkOverflow();
        new MutationObserver(checkOverflow).observe(content, { childList: true, subtree: true });

        section.addEventListener('touchstart', () => {
            section.classList.add('touch-active');
        }, { passive: true });

        section.addEventListener('touchend', () => {
            setTimeout(() => section.classList.remove('touch-active'), 1000);
        }, { passive: true });
    });
}


document.addEventListener('DOMContentLoaded', initScrollContainers);