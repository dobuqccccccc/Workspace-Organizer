//
//  XTTChartViews.swift
//  WorkspaceOrganizer
//
//  Lightweight hand-drawn charts (no third-party SDK).
//

import UIKit

// MARK: - Ring Progress View

/// A circular progress ring with a centered percentage label.
final class XTTRingView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let centerLabel = UILabel()
    private let captionLabel = UILabel()

    private var progress: CGFloat = 0
    var lineWidth: CGFloat = 12
    var progressColor: UIColor = XTTTheme.accent {
        didSet { progressLayer.strokeColor = progressColor.cgColor }
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = XTTTheme.separator.cgColor
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)

        centerLabel.font = XTTTheme.roundedFont(26, .bold)
        centerLabel.textColor = XTTTheme.textPrimary
        centerLabel.textAlignment = .center
        centerLabel.translatesAutoresizingMaskIntoConstraints = false

        captionLabel.font = XTTTheme.font(11, .medium)
        captionLabel.textColor = XTTTheme.textSecondary
        captionLabel.textAlignment = .center
        captionLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [centerLabel, captionLabel])
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: -.pi / 2,
                                endAngle: .pi * 1.5,
                                clockwise: true)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
        trackLayer.lineWidth = lineWidth
        progressLayer.lineWidth = lineWidth
    }

    /// Set progress (0...1) and center caption text.
    func configure(progress: CGFloat, centerText: String, caption: String) {
        self.progress = max(0, min(1, progress))
        centerLabel.text = centerText
        captionLabel.text = caption
        progressLayer.strokeEnd = self.progress
    }
}

// MARK: - Horizontal Bar Chart

struct XTTBarDatum {
    let label: String
    let value: Int
    let color: UIColor
}

/// A simple horizontal bar chart drawn with auto-layout rows (no SDK).
final class XTTBarChartView: UIView {

    private let stack = UIStackView()

    init() {
        super.init(frame: .zero)
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.xtt_pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(data: [XTTBarDatum]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let maxValue = max(data.map { $0.value }.max() ?? 1, 1)
        for datum in data {
            stack.addArrangedSubview(makeRow(datum, maxValue: maxValue))
        }
    }

    private func makeRow(_ datum: XTTBarDatum, maxValue: Int) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = datum.label
        titleLabel.font = XTTTheme.font(13, .medium)
        titleLabel.textColor = XTTTheme.textSecondary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = "\(datum.value)"
        valueLabel.font = XTTTheme.roundedFont(13, .bold)
        valueLabel.textColor = XTTTheme.textPrimary
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let track = UIView()
        track.backgroundColor = XTTTheme.separator.withAlphaComponent(0.4)
        track.layer.cornerRadius = 5
        track.translatesAutoresizingMaskIntoConstraints = false

        let fill = UIView()
        fill.backgroundColor = datum.color
        fill.layer.cornerRadius = 5
        fill.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        container.addSubview(track)
        track.addSubview(fill)

        let ratio = CGFloat(datum.value) / CGFloat(maxValue)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            track.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            track.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            track.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            track.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            track.heightAnchor.constraint(equalToConstant: 10),

            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: max(0.02, ratio))
        ])

        return container
    }
}

// MARK: - Status Distribution Bar

/// A single stacked horizontal bar showing status proportions.
final class XTTSegmentBar: UIView {

    private let stack = UIStackView()

    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        clipsToBounds = true
        backgroundColor = XTTTheme.separator.withAlphaComponent(0.4)

        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.xtt_pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Provide (color, count) segments. Zero-count segments are skipped.
    func configure(segments: [(color: UIColor, count: Int)]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let total = max(segments.reduce(0) { $0 + $1.count }, 1)
        for segment in segments where segment.count > 0 {
            let block = UIView()
            block.backgroundColor = segment.color
            block.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(block)
            block.widthAnchor.constraint(equalTo: stack.widthAnchor,
                                         multiplier: CGFloat(segment.count) / CGFloat(total)).isActive = true
        }
    }
}
