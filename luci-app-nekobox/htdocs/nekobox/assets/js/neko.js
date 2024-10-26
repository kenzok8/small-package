$(document).ready(function () {
    var pth = window.location.pathname;
    if (pth === "/nekobox/settings.php"){
        $.get("./lib/log.php?data=neko_ver", function (result) {
            $('#cliver').html(result);
        });
        $.get("./lib/log.php?data=core_ver", function (result) {
            $('#corever').html(result);
        });
    }
    else{
        setInterval(function() {
            $.get("./lib/log.php?data=neko", function (result) {
                $('#logs').html(result);
            });
            $.get("./lib/log.php?data=bin", function (result) {
                $('#bin_logs').html(result);
            });
            $(document).ready(function () {
                $.ajaxSetup({ cache: false });
                var textarea = document.getElementById("logs");
                textarea.scrollTop = textarea.scrollHeight;
            });
        }, 1000);
        setInterval(function() {
            $(document).ready(function() {
                $.ajaxSetup({ cache: false });
            });
            $.get("./lib/up.php", function (result) {
                $('#uptotal').html(result);
            });
            $.get("./lib/down.php", function (result) {
                $('#downtotal').html(result);
            });
        }, 1000);
    }
});
