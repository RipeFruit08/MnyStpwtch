import SwiftUI

struct SettingsView: View {
    private enum Field: Hashable {
        case hourlyRate
        case annualSalary
        case annualHours
    }

    @AppStorage("UserRate") private var hourlyRate = 19.0
    @AppStorage("AnnualSalary") private var annualSalary = 50_000.0
    @AppStorage("AnnualWorkingHours") private var annualHours = 2_080.0
    @AppStorage("PlayfulLanguage") private var playfulLanguage = true

    @State private var rateText = ""
    @State private var validationMessage: String?
    @FocusState private var focusedField: Field?

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Hourly rate") {
                    TextField("Rate", text: $rateText)
                        .focused($focusedField, equals: .hourlyRate)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 100, maxWidth: 180)
#if !targetEnvironment(macCatalyst)
                        .keyboardType(.decimalPad)
#endif
                        .onSubmit(applyRate)
                }

                Button("Apply Hourly Rate", action: applyRate)
            } header: {
                Text("Earnings")
            } footer: {
                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                } else {
                    Text("The rate is captured when a new session starts, so changing it won’t alter a session already in progress.")
                }
            }

            Section("Salary Converter") {
                LabeledContent("Annual salary") {
                    TextField(
                        "Salary",
                        value: $annualSalary,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .focused($focusedField, equals: .annualSalary)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 100, maxWidth: 180)
#if !targetEnvironment(macCatalyst)
                    .keyboardType(.decimalPad)
#endif
                }

                LabeledContent("Working hours per year") {
                    TextField(
                        "Hours",
                        value: $annualHours,
                        format: .number.precision(.fractionLength(0...1))
                    )
                    .focused($focusedField, equals: .annualHours)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 100, maxWidth: 180)
#if !targetEnvironment(macCatalyst)
                    .keyboardType(.decimalPad)
#endif
                }

                Button("Use Calculated Rate") {
                    guard annualSalary.isFinite, annualSalary >= 0,
                          annualHours.isFinite, annualHours > 0 else {
                        validationMessage = "Enter a nonnegative salary and working hours greater than zero."
                        return
                    }

                    hourlyRate = MoneyMath.validatedRate(annualSalary / annualHours)
                    rateText = hourlyRate.formatted(.number.precision(.fractionLength(2)))
                    validationMessage = nil
                    focusedField = nil
                }

                LabeledContent(
                    "Calculated rate",
                    value: MoneyMath.validatedRate(annualSalary / max(1, annualHours))
                        .formatted(.currency(code: currencyCode))
                )
            }

            Section {
                Toggle("Use playful language", isOn: $playfulLanguage)
            } header: {
                Text("Personality")
            } footer: {
                Text("This keeps the app suitable for both company-time humor and straightforward cost tracking.")
            }

            Section("Data") {
                NavigationLink {
                    TransferDataView()
                } label: {
                    Label("Transfer Data", systemImage: "arrow.left.arrow.right")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .onAppear {
            rateText = hourlyRate.formatted(.number.precision(.fractionLength(2)))
        }
    }

    private func applyRate() {
        guard let parsedRate = Double(rateText), parsedRate.isFinite, parsedRate >= 0 else {
            validationMessage = "Enter a valid nonnegative hourly rate."
            return
        }

        let validatedRate = MoneyMath.validatedRate(parsedRate)
        hourlyRate = validatedRate
        rateText = validatedRate.formatted(.number.precision(.fractionLength(2)))
        validationMessage = parsedRate > MoneyMath.maximumHourlyRate
            ? "The hourly rate was limited to \(MoneyMath.maximumHourlyRate.formatted(.currency(code: currencyCode)))."
            : nil
        focusedField = nil
    }
}
