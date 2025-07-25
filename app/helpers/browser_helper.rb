module BrowserHelper
  def browser_sync_initializer
    tag.script id: "__bs_script__" do
      raw <<-SCRIPT
      (function() {
        try {
          var script = document.createElement('script');
          if ('async') {
            script.async = true;
          }
          script.src = 'http://HOST:3001/browser-sync/browser-sync-client.js?v=3.0.4'.replace("HOST", location.hostname);
          if (document.body) {
            document.body.appendChild(script);
          } else if (document.head) {
            document.head.appendChild(script);
          }
        } catch (e) {
          console.error("Browsersync: could not append script tag", e);
        }
      })()
    SCRIPT
    end
  end
end
