//
//  BrightCheckoutModels.swift
//  Widgets
//

import SwiftUI
import UIKit

struct BrightShippingAddress: Identifiable, Hashable {
    let id: String
    let name: String
    let street: String
    var line1 = ""
    var line2: String?
    var city = ""
    var state: String?
    var postalCode = ""
    var countryCode = ""
    var phone: String?
    var isDefault = false
}

struct BrightShippingOption: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String

    static let standard = BrightShippingOption(
        id: "free-express",
        name: "Free express shipping - FREE",
        detail: "1-3 Business days"
    )
}

struct BrightPaymentMethod: Identifiable, Hashable {
    let id: String
    let name: String
    let markName: String
    let markSize: CGSize
    var markImage: UIImage?
    var last4: String?
    var billing: String?

    static let applePay = BrightPaymentMethod(
        id: "apple-pay",
        name: "Apple Pay",
        markName: ImageNames.paymentApplePayV5,
        markSize: CGSize(width: 38, height: 24.33)
    )
}

struct BrightCheckoutItem {
    let title: String
    var subtitle: String?
    var systemImage: String?
    let detail: String
    let priceText: String
    let currency: String
    let fulfilment: BrightCheckoutFulfilment
}

enum BrightCheckoutFulfilment {
    case shipped
    case delivered
    case inPerson(name: String, address: String)

    var needsAddress: Bool {
        switch self {
        case .shipped, .delivered: true
        case .inPerson: false
        }
    }

    var needsShipping: Bool {
        if case .shipped = self { return true }
        return false
    }
}

enum BrightCheckoutPayment {
    case demo
    case external(BrightPaymentMethod?, choose: () -> Void)
}

struct BrightCheckoutDetails {
    let address: BrightShippingAddress?
    let shipping: BrightShippingOption?
    let paymentMethod: BrightPaymentMethod?
}

struct BrightCountry: Identifiable, Hashable {
    let code: String
    let name: String
    let dialCode: String

    var id: String { code }

    var flag: String {
        code.unicodeScalars.reduce(into: "") { flag, scalar in
            guard let regional = UnicodeScalar(scalar.value + Constants.regionalIndicatorOffset) else { return }
            flag.unicodeScalars.append(regional)
        }
    }

    static let all: [BrightCountry] = Constants.dialCodes
        .split(whereSeparator: \.isWhitespace)
        .compactMap { entry in
            let parts = entry.split(separator: ":")
            guard parts.count == 2 else { return nil }
            let code = String(parts[0])
            guard let name = Locale.bright.localizedString(forRegionCode: code) else { return nil }
            return BrightCountry(code: code, name: name, dialCode: "+\(parts[1])")
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

    static let `default` = all.first { $0.code == Constants.defaultCode } ?? all[0]

    private enum Constants {
        static let regionalIndicatorOffset: UInt32 = 127_397
        static let defaultCode = "AU"
        static let dialCodes = """
        AD:376 AE:971 AF:93 AG:1 AI:1 AL:355 AM:374 AO:244 AR:54 AS:1 AT:43 AU:61 AW:297 AX:358 AZ:994
        BA:387 BB:1 BD:880 BE:32 BF:226 BG:359 BH:973 BI:257 BJ:229 BL:590 BM:1 BN:673 BO:591 BQ:599 BR:55
        BS:1 BT:975 BW:267 BY:375 BZ:501 CA:1 CC:61 CD:243 CF:236 CG:242 CH:41 CI:225 CK:682 CL:56 CM:237
        CN:86 CO:57 CR:506 CU:53 CV:238 CW:599 CX:61 CY:357 CZ:420 DE:49 DJ:253 DK:45 DM:1 DO:1 DZ:213
        EC:593 EE:372 EG:20 EH:212 ER:291 ES:34 ET:251 FI:358 FJ:679 FK:500 FM:691 FO:298 FR:33 GA:241 GB:44
        GD:1 GE:995 GF:594 GG:44 GH:233 GI:350 GL:299 GM:220 GN:224 GP:590 GQ:240 GR:30 GS:500 GT:502 GU:1
        GW:245 GY:592 HK:852 HN:504 HR:385 HT:509 HU:36 ID:62 IE:353 IL:972 IM:44 IN:91 IO:246 IQ:964 IR:98
        IS:354 IT:39 JE:44 JM:1 JO:962 JP:81 KE:254 KG:996 KH:855 KI:686 KM:269 KN:1 KP:850 KR:82 KW:965
        KY:1 KZ:7 LA:856 LB:961 LC:1 LI:423 LK:94 LR:231 LS:266 LT:370 LU:352 LV:371 LY:218 MA:212 MC:377
        MD:373 ME:382 MF:590 MG:261 MH:692 MK:389 ML:223 MM:95 MN:976 MO:853 MP:1 MQ:596 MR:222 MS:1 MT:356
        MU:230 MV:960 MW:265 MX:52 MY:60 MZ:258 NA:264 NC:687 NE:227 NF:672 NG:234 NI:505 NL:31 NO:47 NP:977
        NR:674 NU:683 NZ:64 OM:968 PA:507 PE:51 PF:689 PG:675 PH:63 PK:92 PL:48 PM:508 PR:1 PS:970 PT:351
        PW:680 PY:595 QA:974 RE:262 RO:40 RS:381 RU:7 RW:250 SA:966 SB:677 SC:248 SD:249 SE:46 SG:65 SH:290
        SI:386 SJ:47 SK:421 SL:232 SM:378 SN:221 SO:252 SR:597 SS:211 ST:239 SV:503 SX:1 SY:963 SZ:268 TC:1
        TD:235 TG:228 TH:66 TJ:992 TK:690 TL:670 TM:993 TN:216 TO:676 TR:90 TT:1 TV:688 TW:886 TZ:255 UA:380
        UG:256 US:1 UY:598 UZ:998 VA:39 VC:1 VE:58 VG:1 VI:1 VN:84 VU:678 WF:681 WS:685 YE:967 YT:262 ZA:27
        ZM:260 ZW:263
        """
    }
}
