// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct DocumentPickerViewController {
    private let picker: CustomPicker
    init(picker: CustomPicker) {
        self.picker = picker
    }
}

extension DocumentPickerViewController: UIViewControllerRepresentable {
    typealias UIViewControllerType = CustomPicker

    func makeUIViewController(context: Context) -> UIViewControllerType {
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ObservableObject {
        var parent: DocumentPickerViewController

        init(_ documentPickerController: DocumentPickerViewController) {
            parent = documentPickerController
        }
    }
}
