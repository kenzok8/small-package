/* <![CDATA[ */

async function getUci() {
    try {
        const response = await fetch("/cgi-bin/luci/api/get");
        if (!response.ok) throw new Error("Network error");
        return await response.json();
    } catch (error) {
        console.error("Failed to fetch theme config:", error);
        return {
            success: false,
            bgqs: "0",
            primaryrgbm: "45,102,147",
            primaryrgbmts: "0",
	    mode:'dark'
        };
    }
}
    
function getTimeTheme() {
        var hour = new Date().getHours();
        return (hour < 6 || hour >= 18) ? 'dark' : 'light';
    }

function getSystemTheme() {
        return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

async function updateTheme(theme) {
  const root = document.documentElement;
  const isDark = theme === 'dark';
  try {
    const config = await getUci();
    const primaryRgbbody = isDark ? '33,45,60' : '248,248,248';
    const bgqsValue = config.bgqs; 
    const rgbmValue = config.primaryrgbm; 
    const rgbmtsValue = config.primaryrgbmts;
    let vars = {};
        if (bgqsValue === "0") {
            vars = {
                '--menu-fontcolor': isDark ? '#ddd' : '#f5f5f5',
                '--primary-rgbbody': primaryRgbbody,
                '--bgqs-image': '-webkit-linear-gradient(135deg, rgba(255, 255, 255, 0.1) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.1) 50%, rgba(255, 255, 255, 0.1) 75%, transparent 75%, transparent)',
                '--menu-bgcolor': `rgba(${rgbmValue}, ${rgbmtsValue})`,
                '--menu-item-hover-bgcolor': 'rgba(248,248,248, 0.22)',
                '--menu-item-active-bgcolor': 'rgba(248,248,248, 0.3)',
            };
        } else {
            vars = {
                '--menu-fontcolor': isDark ? '#ddd' : '#4d4d5d',
                '--primary-rgbbody': primaryRgbbody,
                '--menu-bgcolor': `rgba(${primaryRgbbody},${rgbmtsValue})`,
            };
        }
        Object.entries(vars).forEach(([key, value]) => {
        root.style.setProperty(key, value);
      });
        if (window.LuciForm) {
            LuciForm.refreshVisibility();
        }
  } catch (error) {
        console.error('Error updating theme variables:', error);
  }
}
(async function(){
    const config = await getUci();
    var initMode = config.mode; 
    function applyTheme(theme) {
        document.body.setAttribute('data-theme', theme);
        const meta = document.querySelector('meta[name="theme-color"]');
        if (meta) {
            meta.content = theme === 'dark' ? '#1a1a1a' : '#ffffff';
        }
    }

    (async function() {
        if (initMode === 'auto') {
	    var autoTheme = getSystemTheme() === 'light' ? 'light' : getTimeTheme();
            applyTheme(autoTheme);
            await updateTheme(autoTheme);
        } 
        else {
            applyTheme(initMode);
            await updateTheme(initMode);
        }
    })();
})();
/* ]]> */
