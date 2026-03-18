import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Customizes the shield UI shown when an app limit is reached.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 0.95),
            icon: UIImage(systemName: "timer"),
            title: ShieldConfiguration.Label(
                text: "Time's Up!",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You've reached your screen time limit for this app.",
                color: UIColor(white: 0.7, alpha: 1)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Got it",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.49, green: 0.36, blue: 0.99, alpha: 1)
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }
}
