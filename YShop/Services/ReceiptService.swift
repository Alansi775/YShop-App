import Foundation
import UIKit

final class ReceiptService {
    /// Generate a simple black & white PDF receipt for the given order.
    /// Uses app `Logo` asset if available.
    static func generateReceiptPDF(order: Order, store: Store?, customer: SimpleUser?) -> Data {
        let pageWidth: CGFloat = 595.2 // A4 width in points
        let pageHeight: CGFloat = 841.8 // A4 height in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let format = UIGraphicsPDFRendererFormat()
        let meta: [String: Any] = [
            kCGPDFContextTitle as String: "YSHOP Receipt",
            kCGPDFContextCreator as String: "YShop iOS"
        ]
        format.documentInfo = meta as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            // Centered content area and header
            let contentMargin: CGFloat = 80
            let marginTop: CGFloat = 40
            var y: CGFloat = marginTop
            let contentX = contentMargin
            let contentWidth = pageWidth - contentMargin * 2

            // Brand header: textual YSHOP (match splash style weight)
            let brandFont = UIFont.systemFont(ofSize: 36, weight: .black)
            let brandAttr: [NSAttributedString.Key: Any] = [
                .font: brandFont,
                .foregroundColor: UIColor.black
            ]
            let brand = "YSHOP"
            let brandSize = (brand as NSString).size(withAttributes: brandAttr)
            let brandX = (pageWidth - brandSize.width) / 2
            (brand as NSString).draw(at: CGPoint(x: brandX, y: y), withAttributes: brandAttr)
            y += brandSize.height + 12

            // Title
            let title = "YSHOP Receipt"
            let titleAttr: [NSAttributedString.Key: Any] = [ .font: UIFont.boldSystemFont(ofSize: 20) ]
            let titleSize = (title as NSString).size(withAttributes: titleAttr)
            (title as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: titleAttr)
            y += titleSize.height + 8

            // Order meta
            let metaFont = UIFont.systemFont(ofSize: 12)
            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
            let orderMeta = "Order: \(order.id)    Date: \(dateStr)"
            (orderMeta as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: [.font: metaFont])
            y += 20

            if let customerName = customer?.name {
                ("Customer: \(customerName)" as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: [.font: metaFont])
                y += 18
            }

            if let customerEmail = customer?.email {
                ("Email: \(customerEmail)" as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: [.font: metaFont])
                y += 18
            }

            if let storeName = store?.name {
                ("Store: \(storeName)" as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: [.font: metaFont])
                y += 18
            }

            if let shippingAddress = order.shippingAddress ?? order.deliveryAddress {
                let addressLabel = "Shipping Address: \(shippingAddress)"
                let addressRect = CGRect(x: contentX, y: y, width: contentWidth, height: 48)
                addressLabel.draw(in: addressRect, withAttributes: [.font: metaFont])
                y += 34
            }

            // Payment method & status
            let paymentMethod = order.paymentMethod ?? ""
            let isPayAtDoor = paymentMethod.lowercased() == "pay at door"
            if !paymentMethod.isEmpty {
                ("Payment Method: \(paymentMethod)" as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: [.font: metaFont])
                y += 18
            }
            let paymentStatusLabel = isPayAtDoor
                ? "Payment Status: Pending — Pay at Door upon delivery"
                : "Payment Status: Confirmed"
            let statusColor = isPayAtDoor ? UIColor(red: 0.6, green: 0.4, blue: 0, alpha: 1) : UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1)
            (paymentStatusLabel as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: statusColor])
            y += 22

            y += 8

            // Items header
            let headerFont = UIFont.boldSystemFont(ofSize: 13)
            ("Item" as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: [.font: headerFont])
            let rightAreaX = contentX + contentWidth
            ("Qty" as NSString).draw(at: CGPoint(x: rightAreaX - 200, y: y), withAttributes: [.font: headerFont])
            ("Price" as NSString).draw(at: CGPoint(x: rightAreaX - 120, y: y), withAttributes: [.font: headerFont])
            ("Total" as NSString).draw(at: CGPoint(x: rightAreaX - 20, y: y), withAttributes: [.font: headerFont])
            y += 18

            let bodyFont = UIFont.systemFont(ofSize: 12)
            let imageSize: CGFloat = 44
            for item in order.items {
                let name = item.displayName
                let qty = "\(item.quantity)"
                let price = String(format: "%.2f", item.price)
                let lineTotal = String(format: "%.2f", item.price * Double(item.quantity))
                let itemTotal = item.price * Double(item.quantity)

                // Wrap name if needed
                let maxNameWidth = contentWidth - 220
                let nameAttr: [NSAttributedString.Key: Any] = [.font: bodyFont]
                let nameStr = NSString(string: name)
                let nameSize = nameStr.boundingRect(with: CGSize(width: maxNameWidth, height: 1000), options: [.usesLineFragmentOrigin], attributes: nameAttr, context: nil)

                if let image = colorThumbnail(for: item) {
                    let imageRect = CGRect(x: contentX, y: y, width: imageSize, height: imageSize)
                    image.draw(in: imageRect)
                } else {
                    UIColor.white.setFill()
                    UIBezierPath(rect: CGRect(x: contentX, y: y, width: imageSize, height: imageSize)).fill()
                    UIColor.black.setStroke()
                    UIBezierPath(rect: CGRect(x: contentX, y: y, width: imageSize, height: imageSize)).stroke()
                }

                let textX = contentX + imageSize + 12
                nameStr.draw(in: CGRect(x: textX, y: y, width: maxNameWidth, height: nameSize.height), withAttributes: nameAttr)

                // Draw qty/price/total aligned (right aligned columns) within content area
                let qtyRect = CGRect(x: rightAreaX - 200, y: y + 2, width: 40, height: 18)
                let priceRect = CGRect(x: rightAreaX - 120, y: y + 2, width: 80, height: 18)
                let totalRect = CGRect(x: rightAreaX - 20, y: y + 2, width: 60, height: 18)
                let rightPara = NSMutableParagraphStyle()
                rightPara.alignment = .right
                let rightAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .paragraphStyle: rightPara]
                (qty as NSString).draw(in: qtyRect, withAttributes: rightAttr)
                (price as NSString).draw(in: priceRect, withAttributes: rightAttr)
                (lineTotal as NSString).draw(in: totalRect, withAttributes: rightAttr)

                y += max(max(nameSize.height, imageSize), 18) + 10

                // Page break if needed
                if y > pageHeight - marginTop - 80 {
                    context.beginPage()
                    y = marginTop
                }
            }

            // Divider
            y += 6
            context.cgContext.setLineWidth(0.5)
            context.cgContext.move(to: CGPoint(x: contentX, y: y))
            context.cgContext.addLine(to: CGPoint(x: contentX + contentWidth, y: y))
            context.cgContext.strokePath()
            y += 10

            // Totals
            let totalLabelFont = UIFont.boldSystemFont(ofSize: 14)
            let grandLabel = "Grand Total"
            let totalStr = String(format: "%.2f", order.totalPrice)
            // Draw label on the left of content area and value right-aligned inside content area
            (grandLabel as NSString).draw(at: CGPoint(x: contentX, y: y), withAttributes: [.font: totalLabelFont])
            let totalRect = CGRect(x: contentX, y: y, width: contentWidth, height: 18)
            let rightPara2 = NSMutableParagraphStyle()
            rightPara2.alignment = .right
            (totalStr as NSString).draw(in: totalRect, withAttributes: [.font: totalLabelFont, .paragraphStyle: rightPara2])
            y += 28

            // Footer / small note
            let note = isPayAtDoor
                ? "Payment is due upon delivery. Please have the exact amount ready. Thank you for shopping with YSHOP."
                : "Payment has been received. Thank you for shopping with YSHOP."
            let noteFont = UIFont.systemFont(ofSize: 11)
            (note as NSString).draw(in: CGRect(x: contentX, y: y, width: contentWidth, height: 60), withAttributes: [.font: noteFont])
        }

        return data
    }

    private static func colorThumbnail(for item: CartItem) -> UIImage? {
        guard let imageURLString = item.fullImageUrl, let url = URL(string: imageURLString) else { return nil }
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return nil }
        return image
    }

    /// Upload the generated PDF to the backend which will send the email.
    /// The backend endpoint is expected to accept a multipart `file` field and parameters `recipientEmail` and `recipientType`.
    static func sendReceipt(orderId: String, pdfData: Data, recipientEmail: String, recipientType: String = "customer") async throws -> EmptyResponse {
        let filename = "receipt_\(orderId).pdf"
        let response: EmptyResponse = try await APIClient.shared.uploadMultipart(
            .sendOrderReceipt(orderId),
            parameters: ["recipientEmail": recipientEmail, "recipientType": recipientType],
            fileData: pdfData,
            fileName: filename,
            mimeType: "application/pdf"
        )
        return response
    }
}
