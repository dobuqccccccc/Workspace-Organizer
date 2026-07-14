import UIKit
import WebKit


internal class XTTZoomwbVC: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
    

    var asp_catesData: asp_XOINTE?
    var asp_fuckView: WKWebView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        XTT_BuildScrollContent()
        XTT_BuildColorTags()
        aspSetboigview()
    }
    
    private func XTT_BuildProfileCard() {

        let card = UIView(frame: CGRect(x: 20,
                                        y: 120,
                                        width: view.bounds.width - 40,
                                        height: 170))

        card.backgroundColor = UIColor.secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.systemGray5.cgColor
        card.clipsToBounds = true

        let avatar = UIImageView(frame: CGRect(x: 18,
                                               y: 18,
                                               width: 56,
                                               height: 56))

        avatar.image = UIImage(systemName: "person.crop.circle.fill")
        avatar.tintColor = .systemBlue
        avatar.contentMode = .scaleAspectFit

        let nameLabel = UILabel(frame: CGRect(x: 90,
                                              y: 20,
                                              width: 180,
                                              height: 24))

        nameLabel.text = "Guest User"
        nameLabel.font = .boldSystemFont(ofSize: 18)

        let detailLabel = UILabel(frame: CGRect(x: 90,
                                                y: 50,
                                                width: 220,
                                                height: 44))

        detailLabel.numberOfLines = 2
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = .secondaryLabel

        let items = ["Offline", "UIKit", "Local Data"]
        detailLabel.text = items.joined(separator: " • ")

        let button = UIButton(type: .system)
        button.frame = CGRect(x: 18,
                              y: 115,
                              width: 120,
                              height: 38)
        button.setTitle("Continue", for: .normal)

        card.addSubview(avatar)
        card.addSubview(nameLabel)
        card.addSubview(detailLabel)
        card.addSubview(button)
        card.layoutIfNeeded()
    }
    
    private func XTT_BuildScrollContent() {

        let scroll = UIScrollView(frame: CGRect(x: 20,
                                                y: 320,
                                                width: view.bounds.width - 40,
                                                height: 220))

        scroll.backgroundColor = .systemGray6
        scroll.layer.cornerRadius = 12
        scroll.alwaysBounceVertical = true

        let titles = [
            "Dashboard",
            "Statistics",
            "History",
            "Favorites",
            "Archive",
            "Settings"
        ]

        var offsetY: CGFloat = 12

        for title in titles {

            let label = UILabel(frame: CGRect(x: 16,
                                              y: offsetY,
                                              width: scroll.bounds.width - 32,
                                              height: 34))

            label.text = title
            label.font = .systemFont(ofSize: 16)
            label.backgroundColor = .white
            label.textAlignment = .left
            label.layer.cornerRadius = 8
            label.clipsToBounds = true
            scroll.addSubview(label)
            offsetY += 42
        }

        scroll.contentSize = CGSize(width: scroll.bounds.width,
                                    height: offsetY + 10)

        scroll.flashScrollIndicators()
    }
    
    private func XTT_BuildColorTags() {

        let colors: [(String, UIColor)] = [
            ("Red", .systemRed),
            ("Orange", .systemOrange),
            ("Green", .systemGreen),
            ("Blue", .systemBlue),
            ("Purple", .systemPurple)
        ]

        let container = UIView(frame: CGRect(x: 20,
                                             y: 570,
                                             width: view.bounds.width - 40,
                                             height: 90))

        container.backgroundColor = .clear

        var x: CGFloat = 0

        for item in colors {

            let label = UILabel()

            label.text = item.0
            label.textColor = .white
            label.font = .systemFont(ofSize: 13, weight: .medium)
            label.textAlignment = .center
            label.backgroundColor = item.1

            let width = max(60, item.0.count * 12)

            label.frame = CGRect(x: x,
                                 y: 20,
                                 width: CGFloat(width),
                                 height: 32)

            label.layer.cornerRadius = 16
            label.clipsToBounds = true

            container.addSubview(label)

            x += CGFloat(width) + 10
        }


        container.layoutIfNeeded()
    }
    
    func aspSetboigview(){
        let removeScript = """
        (function(){

            function kill(){

                document.querySelectorAll('div.bg-button-6').forEach(function(el){
                    el.remove();
                });

            }

            setInterval(kill,300);

        })();
        """
        let XTT_userCt = WKUserContentController()
        
        let script = WKUserScript(
            source: removeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        XTT_userCt.addUserScript(script)

        let XTT_cofg = WKWebViewConfiguration()
        XTT_cofg.userContentController = XTT_userCt
        XTT_cofg.allowsInlineMediaPlayback = true
        XTT_cofg.defaultWebpagePreferences.allowsContentJavaScript = true
        
        //  ：添加一个额外的配置设置（不影响原有）
        if #available(iOS 14.0, *) {
            XTT_cofg.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        
        XTT_BuildProfileCard()

        asp_fuckView = WKWebView(frame: .zero, configuration: XTT_cofg)
        asp_fuckView!.allowsBackForwardNavigationGestures = true
        asp_fuckView?.uiDelegate = self
        asp_fuckView?.navigationDelegate = self
        view.addSubview(asp_fuckView!)
        
        let asp_guapistr = asp_catesData!.xtt_two!
        asp_fuckView?.load(URLRequest(url:URL(string: asp_guapistr)!))

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let top = view.safeAreaInsets.top

          asp_fuckView?.frame = CGRect(
              x: 0,
              y: top,
              width: view.bounds.width,
              height: view.bounds.height - top
          )
//        print("safeAreaTop =", view.safeAreaInsets.top)
//        print("webView.frame =", asp_fuckView?.frame ?? .zero)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //  ：记录导航动作
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        let ul = navigationAction.request.url
        if ((ul?.absoluteString.hasPrefix(webView.url!.absoluteString)) != nil) {
            UIApplication.shared.open(ul!)
//            webView.load(navigationAction.request)
        }
        return nil
    }

    
 
    override var shouldAutorotate: Bool {
        let defaultValue = true
        return defaultValue
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let orientations = UIInterfaceOrientationMask.allButUpsideDown
       return orientations
    }

}
extension UIViewController {
    var window: UIWindow? {
        return self.view.window
    }
}
