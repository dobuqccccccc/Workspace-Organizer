//
//  XTTEditItemViewController.swift
//  WorkspaceOrganizer
//
//  Add or edit an item inside a kit.
//

import UIKit

final class XTTEditItemViewController: UIViewController {

    private let kitID: String
    private let existingItem: XTTItem?
    private var isEditingItem: Bool { existingItem != nil }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Photo
    private let photoButton = UIButton(type: .system)
    private let photoView = UIImageView()
    private let photoHint = UILabel()
    private var pickedImage: UIImage?
    private var pickedPhotoFileName: String?
    private var photoWasRemoved = false

    // Fields
    private let nameRow = XTTFieldRow(label: "Item Name", placeholder: "e.g. Flashlight")
    private let categorySelector = XTTChipSelector()
    private let statusSelector = XTTChipSelector()
    private let quantityRow = XTTStepperRow(label: "Quantity", initial: 1)
    private let locationRow = XTTFieldRow(label: "Location", placeholder: "e.g. Garage shelf")
    private let expiryRow = XTTDateRow(label: "Expiration Date")
    private let notesRow = XTTNotesRow(label: "Notes", placeholder: "Optional notes")

    init(kitID: String, item: XTTItem?) {
        self.kitID = kitID
        self.existingItem = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = isEditingItem ? "Edit Item" : "New Item"
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

        contentStack.addArrangedSubview(makePhotoPicker())
        contentStack.addArrangedSubview(nameRow)
        contentStack.addArrangedSubview(makeSelectorBlock(title: "Category", selector: categorySelector))
        contentStack.addArrangedSubview(quantityRow)
        contentStack.addArrangedSubview(makeSelectorBlock(title: "Status", selector: statusSelector))
        contentStack.addArrangedSubview(locationRow)
        contentStack.addArrangedSubview(expiryRow)
        contentStack.addArrangedSubview(notesRow)

        categorySelector.configure(
            options: XTTItemCategory.allCases.map { ($0, $0.rawValue, XTTTheme.accent) },
            selected: existingItem?.category ?? .other)
        statusSelector.configure(
            options: XTTItemStatus.allCases.map { ($0, $0.rawValue, $0.color) },
            selected: existingItem?.status ?? .ready)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func makeSelectorBlock(title: String, selector: XTTChipSelector) -> UIView {
        let caption = UILabel()
        caption.text = title
        caption.font = XTTTheme.font(13, .semibold)
        caption.textColor = XTTTheme.textSecondary
        let stack = UIStackView(arrangedSubviews: [caption, selector])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func makePhotoPicker() -> UIView {
        let container = UIView()
        container.backgroundColor = XTTTheme.card
        container.layer.cornerRadius = XTTTheme.Radius.medium
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = XTTTheme.separator.cgColor
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 140).isActive = true

        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(photoView)
        photoView.xtt_pinEdges(to: container)

        let overlay = UIStackView()
        overlay.axis = .vertical
        overlay.alignment = .center
        overlay.spacing = 8
        overlay.isUserInteractionEnabled = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "camera.fill"))
        icon.tintColor = XTTTheme.accent
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        photoHint.text = "Add Photo"
        photoHint.font = XTTTheme.font(14, .medium)
        photoHint.textColor = XTTTheme.textSecondary
        overlay.addArrangedSubview(icon)
        overlay.addArrangedSubview(photoHint)
        container.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        photoButton.translatesAutoresizingMaskIntoConstraints = false
        photoButton.addTarget(self, action: #selector(pickPhoto), for: .touchUpInside)
        container.addSubview(photoButton)
        photoButton.xtt_pinEdges(to: container)

        // long-press to remove
        let remove = UILongPressGestureRecognizer(target: self, action: #selector(removePhoto))
        container.addGestureRecognizer(remove)

        return container
    }

    private func populate() {
        guard let item = existingItem else { return }
        nameRow.textField.text = item.name
        quantityRow.setValue(item.quantity)
        locationRow.textField.text = item.location
        notesRow.textView.text = item.notes
        if let expiration = item.expirationDate {
            expiryRow.configure(date: expiration)
        }
        if let photo = XTTImageStore.load(item.photoFileName) {
            pickedImage = photo
            photoView.image = photo
            photoHint.superview?.isHidden = true
        }
    }

    // MARK: - Photo Picker

    @objc private func pickPhoto() {
        dismissKeyboard()
        let picker = UIImagePickerController()
        picker.delegate = self
        let alert = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                picker.sourceType = .camera
                self?.present(picker, animated: true)
            })
        }
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            picker.sourceType = .photoLibrary
            self?.present(picker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = photoButton
            pop.sourceRect = photoButton.bounds
        }
        present(alert, animated: true)
    }

    @objc private func removePhoto(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, pickedImage != nil else { return }
        pickedImage = nil
        photoWasRemoved = true
        photoView.image = nil
        photoHint.superview?.isHidden = false
    }

    // MARK: - Save

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let name = nameRow.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            xtt_alert(title: "Name Required", message: "Please enter an item name.")
            return
        }

        // Resolve photo file name.
        var photoFileName = existingItem?.photoFileName
        if photoWasRemoved {
            XTTImageStore.delete(existingItem?.photoFileName)
            photoFileName = nil
        }
        if let picked = pickedImage, pickedPhotoFileName == nil,
           picked != XTTImageStore.load(existingItem?.photoFileName) {
            // Save new image (replace any previous file).
            if let old = existingItem?.photoFileName { XTTImageStore.delete(old) }
            photoFileName = XTTImageStore.save(picked)
        }

        var item = existingItem ?? XTTItem(name: name)
        item.name = name
        item.category = categorySelector.selectedValue(XTTItemCategory.self) ?? .other
        item.status = statusSelector.selectedValue(XTTItemStatus.self) ?? .ready
        item.quantity = quantityRow.value
        item.location = locationRow.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        item.notes = notesRow.textView.text ?? ""
        item.expirationDate = expiryRow.selectedDate
        item.photoFileName = photoFileName

        if isEditingItem {
            XTTDataStore.shared.updateItem(item, inKit: kitID)
        } else {
            XTTDataStore.shared.addItem(item, toKit: kitID)
        }
        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - Image Picker Delegate

extension XTTEditItemViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        pickedImage = image
        pickedPhotoFileName = nil
        photoWasRemoved = false
        photoView.image = image
        photoHint.superview?.isHidden = true
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
