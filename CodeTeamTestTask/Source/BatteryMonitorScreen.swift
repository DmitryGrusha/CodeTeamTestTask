import UIKit

final class BatteryMonitorScreen: UIViewController {
  
  private let viewModel: BatteryMonitorViewModel
  
  init(viewModel: BatteryMonitorViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    viewModel.input.start()
  }
}
