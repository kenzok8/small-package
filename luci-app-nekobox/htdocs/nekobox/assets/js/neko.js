$(document).ready(function () {
    $.ajaxSetup({ cache: false });
    setInterval(function() {
        $.get("./lib/log.php?data=neko", function (result) {
            $('#logs').html(result);
        });
        $.get("./lib/log.php?data=bin", function (result) {
            $('#bin_logs').html(result);
        });

        var textarea = document.getElementById("logs");
        if (textarea) {
            textarea.scrollTop = textarea.scrollHeight;
        }
    }, 1000);

    setInterval(function() {
        $.get("./lib/up.php", function (result) {
            $('#uptotal').html(result);
        });
        $.get("./lib/down.php", function (result) {
            $('#downtotal').html(result);
        });
    }, 1000);

    var pth = window.location.pathname;
    if (pth === "/nekobox/settings.php") {
        $.get("./lib/log.php?data=neko_ver", function (result) {
            $('#cliver').html(result);
        });
        $.get("./lib/log.php?data=core_ver", function (result) {
            $('#corever').html(result);
        });
    }
});