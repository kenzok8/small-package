// 处理openwrt页面的三级菜单
function initTabmenus() {
    L.require("ui").then(function (ui) {
        var renderTabMenu = function (tree, url, level) {
            var container = document.querySelector('#tabmenu')
            var ul = E('ul', { 'class': 'tabs' })
            var children = ui.menu.getChildren(tree)
            for (var i = 0; i < children.length; i++) {
                var isActive = (L.env.dispatchpath[3 + (level || 0)] == children[i].name)
                var activeClass = isActive ? ' active' : ''
                var className = 'tabmenu-item-%s %s'.format(children[i].name, activeClass)
                var elA = [E('a', { 'href': L.url(url, children[i].name) }, [_(children[i].title)])]
                var el = E('li', { 'class': className }, elA)
                ul.appendChild(el);
            }
            if (ul.children.length == 0) {
                return E([]);
            }
            container.appendChild(ul);
            container.style.display = '';
            return ul;
        }
        var Fu = function (tree) {
            var node = tree
            var url = ''
            if (L.env.dispatchpath.length >= 3) {
                for (var i = 0; i < 3 && node; i++) {
                    node = node.children[L.env.dispatchpath[i]];
                    url = url + (url ? '/' : '') + L.env.dispatchpath[i];
                }
                if (node) {
                    renderTabMenu(node, url);
                }
            }
        }
        ui.menu.load().then(L.bind(Fu))
    })
}
initTabmenus()