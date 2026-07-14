//
//  XTTEditKitViewController.swift
//  WorkspaceOrganizer
//
//  Add or edit an emergency kit (name, category, description, cover image).
//

import UIKit

final class XTTEditKitViewController: UIViewController {

    private let existingKit: XTTKit?
    private var isEditingKit: Bool { existingKit != nil }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let coverButton = UIButton(type: .system)
    private let coverImageView = UIImageView()
    private let coverHint = UILabel()

    private let nameRow = XTTFieldRow(label: "Kit Name", placeholder: "e.g. Home Emergency Kit")
    private let categorySelector = XTTChipSelector()
    private let notesRow = XTTNotesRow(label: "Description", placeholder: "Optional notes about this kit")

    private var pickedImage: UIImage?
    private var pickedCoverFileName: String?

    init(kit: XTTKit?) {
        self.existingKit = kit
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = isEditingKit ? "Edit Kit" : "New Kit"
        setupNavButtons()
        setupLayout()
        populate()
    }

    private func setupNavButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self, action: #selector(saveTapped))
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = XTTTheme.Spacing.l
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: XTTTheme.Spacing.l),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.m),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.m),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -XTTTheme.Spacing.xl),
            contentStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * XTTTheme.Spacing.m)
        ])

        contentStack.addArrangedSubview(makeCoverPicker())

        let categoryContainer = UIStackView()
        categoryContainer.axis = .vertical
        categoryContainer.spacing = 8
        let categoryCaption = UILabel()
        categoryCaption.text = "Category"
        categoryCaption.font = XTTTheme.font(13, .semibold)
        categoryCaption.textColor = XTTTheme.textSecondary
        categoryContainer.addArrangedSubview(categoryCaption)
        categoryContainer.addArrangedSubview(categorySelector)

        categorySelector.configure(
            options: XTTKitCategory.allCases.map { ($0, $0.rawValue, $0.tint) },
            selected: existingKit?.category ?? .home)

        contentStack.addArrangedSubview(nameRow)
        contentStack.addArrangedSubview(categoryContainer)
        contentStack.addArrangedSubview(notesRow)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func makeCoverPicker() -> UIView {
        let container = UIView()
        container.backgroundColor = XTTTheme.card
        container.layer.cornerRadius = XTTTheme.Radius.medium
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = XTTTheme.separator.cgColor
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 150).isActive = true

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(coverImageView)
        coverImageView.xtt_pinEdges(to: container)

        let overlay = UIStackView()
        overlay.axis = .vertical
        overlay.alignment = .center
        overlay.spacing = 8
        overlay.isUserInteractionEnabled = false
        overlay.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "photo.badge.plus"))
        icon.tintColor = XTTTheme.accent
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)

        coverHint.text = "Add Cover Image"
        coverHint.font = XTTTheme.font(14, .medium)
        coverHint.textColor = XTTTheme.textSecondary

        overlay.addArrangedSubview(icon)
        overlay.addArrangedSubview(coverHint)
        container.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        coverButton.translatesAutoresizingMaskIntoConstraints = false
        coverButton.addTarget(self, action: #selector(pickCover), for: .touchUpInside)
        container.addSubview(coverButton)
        coverButton.xtt_pinEdges(to: container)

        return container
    }

    private func populate() {
        guard let kit = existingKit else { return }
        nameRow.textField.text = kit.name
        notesRow.text = kit.detail
        pickedCoverFileName = kit.coverFileName
        if let image = XTTImageStore.load(kit.coverFileName) {
            coverImageView.image = image
            coverHint.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func pickCover() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        let name = (nameRow.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            xtt_alert(title: "Name Required", message: "Please give your kit a name.")
            return
        }

        // Persist a freshly picked image.
        if let image = pickedImage {
            if let old = existingKit?.coverFileName { XTTImageStore.delete(old) }
            pickedCoverFileName = XTTImageStore.save(image)
        }

        let category = categorySelector.selectedValue(XTTKitCategory.self) ?? .home
        let detail = notesRow.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if var kit = existingKit {
            kit.name = name
            kit.category = category
            kit.detail = detail
            kit.coverFileName = pickedCoverFileName
            XTTDataStore.shared.updateKit(kit)
        } else {
            let kit = XTTKit(name: name, category: category, detail: detail, coverFileName: pickedCoverFileName)
            XTTDataStore.shared.addKit(kit)
        }
        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - Image Picker

extension XTTEditKitViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                              didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            pickedImage = image
            coverImageView.image = image
            coverHint.isHidden = true
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
