//
//  VaultMarkerIcon.swift
//  Bright
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import Foundation

/// Maps a marker's display name to an SF Symbol shown to the left of its title
/// in the Vault Overview and Data lists. Lookup is case-insensitive; anything
/// not in the catalog falls back to a neutral symbol.
///
/// Covers the canonical data points: 134 clinical lab markers, 17 biometric /
/// wearable markers, and 37 nutrition markers.
enum VaultMarkerIcon {
    /// Generic backup when nothing more specific matches.
    static let fallback = "cross.case.fill"

    static func systemImage(for name: String) -> String {
        let key = normalize(name)
        if let exact = symbols[key] { return exact }
        if let related = relatedSymbol(for: key) { return related }
        return fallback
    }

    private static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Keyword → symbol rules, checked in order (most specific first). Lets an
    /// unmapped marker fall back to a *related* icon rather than the generic one.
    private static func relatedSymbol(for key: String) -> String? {
        let rules: [(keywords: [String], symbol: String)] = [
            (["cholesterol", "hdl", "ldl", "triglyceride", "lipoprotein", "apolipo", "apob", "heart", "cardio", "bnp"], "heart.fill"),
            (["sleep", "rem"], "bed.double.fill"),
            (["oxygen", "respirat", "lung", "vo2"], "lungs.fill"),
            (["thyroid", "tsh", "t3", "t4"], "waveform.path.ecg"),
            (["testosterone", "estrogen", "estradiol", "hormone", "progesterone", "prolactin", "dhea", "shbg"], "bolt.heart.fill"),
            (["cortisol", "stress", "brain"], "brain.head.profile"),
            (["glucose", "insulin", "hba1c", "metabolic", "calorie", "energy"], "flame.fill"),
            (["vitamin", "folate", "biotin", "niacin", "thiamin", "riboflavin", "mineral", "pill"], "pills.fill"),
            (["omega", "fish"], "fish"),
            (["iron", "ferritin", "transferrin", "mercury", "lead", "arsenic", "cadmium", "aluminum", "zinc", "copper", "magnesium", "metal"], "atom"),
            (["immun", "microb", "gut", "antibod", "globulin"], "microbe"),
            (["inflamm", "crp", "allerg", "ana", "rheumat"], "allergens"),
            (["protein", "albumin", "amino"], "fork.knife"),
            (["fiber", "leaf", "vegetable"], "leaf.fill"),
            (["sugar"], "cube.fill"),
            (["age", "longevity", "telomere", "nad", "glycation"], "hourglass"),
            (["step", "activity", "walk", "strain"], "figure.walk"),
            (["urine", "urinalysis", "blood", "cell", "hemoglobin", "platelet", "water", "hydration", "fat", "lipid"], "drop.fill"),
            (["score"], "chart.bar.fill"),
        ]
        for rule in rules where rule.keywords.contains(where: key.contains) {
            return rule.symbol
        }
        return nil
    }

    /// Keyed by lowercased display name. Symbols are grouped by category so the
    /// list reads coherently; tweak individual entries freely.
    private static let symbols: [String: String] = [
        // MARK: - Clinical

        "white blood cells": "drop.fill",
        "red blood cells": "drop.fill",
        "hemoglobin": "drop.fill",
        "hematocrit": "drop.fill",
        "mean corpuscular volume": "drop.fill",
        "mean corpuscular hemoglobin": "drop.fill",
        "mean corpuscular hemoglobin concentration": "drop.fill",
        "red cell distribution width": "drop.fill",
        "platelets": "drop.fill",
        "mean platelet volume": "drop.fill",
        "neutrophils": "drop.fill",
        "lymphocytes": "drop.fill",
        "monocytes": "drop.fill",
        "eosinophils": "drop.fill",
        "basophils": "drop.fill",
        "immature granulocytes": "drop.fill",

        "glucose": "bolt.fill",
        "calcium": "bolt.fill",
        "sodium": "bolt.fill",
        "potassium": "bolt.fill",
        "chloride": "bolt.fill",
        "carbon dioxide": "bolt.fill",
        "blood urea nitrogen": "bolt.fill",
        "creatinine": "bolt.fill",
        "egfr": "bolt.fill",
        "bun/creatinine ratio": "bolt.fill",

        "alt": "cross.case.fill",
        "ast": "cross.case.fill",
        "alp": "cross.case.fill",
        "ggt": "cross.case.fill",
        "bilirubin (total)": "cross.case.fill",
        "albumin": "cross.case.fill",
        "globulin": "cross.case.fill",
        "total protein": "cross.case.fill",
        "albumin/globulin ratio": "cross.case.fill",

        "total cholesterol": "heart.fill",
        "hdl cholesterol": "heart.fill",
        "ldl cholesterol": "heart.fill",
        "triglycerides": "heart.fill",
        "non-hdl cholesterol": "heart.fill",
        "vldl": "heart.fill",
        "apolipoprotein b": "heart.fill",
        "apolipoprotein a1": "heart.fill",
        "apob/apoa1 ratio": "heart.fill",
        "lipoprotein(a)": "heart.fill",
        "ldl particle number": "heart.fill",
        "ldl particle size": "heart.fill",
        "ldl small": "heart.fill",
        "ldl medium": "heart.fill",
        "hdl large": "heart.fill",
        "vldl size": "heart.fill",

        "fasting glucose": "flame.fill",
        "fasting insulin": "flame.fill",
        "hba1c": "flame.fill",
        "homa-ir": "flame.fill",
        "c-peptide": "flame.fill",
        "fructosamine": "flame.fill",

        "hscrp": "allergens",
        "crp": "allergens",
        "homocysteine": "allergens",
        "esr": "allergens",
        "fibrinogen": "allergens",
        "glyca": "allergens",

        "iron": "atom",
        "ferritin": "atom",
        "transferrin": "atom",
        "tibc": "atom",
        "iron saturation": "atom",

        "tsh": "waveform.path.ecg",
        "free t3": "waveform.path.ecg",
        "free t4": "waveform.path.ecg",
        "reverse t3": "waveform.path.ecg",
        "thyroid peroxidase antibodies": "waveform.path.ecg",
        "thyroglobulin antibodies": "waveform.path.ecg",

        "total testosterone": "bolt.heart.fill",
        "free testosterone": "bolt.heart.fill",
        "shbg": "bolt.heart.fill",
        "dhea-s": "bolt.heart.fill",
        "lh": "bolt.heart.fill",
        "fsh": "bolt.heart.fill",
        "estradiol": "bolt.heart.fill",
        "progesterone": "bolt.heart.fill",
        "amh": "bolt.heart.fill",
        "prolactin": "bolt.heart.fill",

        "cortisol": "brain.head.profile",

        "vitamin d": "pills.fill",
        "vitamin b12": "pills.fill",
        "folate": "pills.fill",
        "magnesium": "pills.fill",
        "zinc": "pills.fill",
        "copper": "pills.fill",
        "selenium": "pills.fill",
        "vitamin a": "pills.fill",
        "vitamin e": "pills.fill",
        "vitamin k": "pills.fill",
        "omega-3 index": "fish",
        "omega-6:3 ratio": "fish",

        "nt-probnp": "heart.fill",

        "cystatin c": "drop.fill",
        "uric acid": "drop.fill",
        "urine albumin": "drop.fill",
        "albumin/creatinine ratio": "drop.fill",

        "lipase": "cross.case.fill",
        "amylase": "cross.case.fill",

        "ana": "allergens",
        "anti-dsdna": "allergens",
        "rheumatoid factor": "allergens",
        "anti-ccp": "allergens",

        "immunoglobulin a": "microbe",
        "immunoglobulin g": "microbe",
        "immunoglobulin m": "microbe",

        "mercury": "atom",
        "lead": "atom",
        "arsenic": "atom",
        "cadmium": "atom",
        "aluminum": "atom",

        "calprotectin": "microbe",
        "zonulin": "microbe",
        "pancreatic elastase": "microbe",
        "short chain fatty acids": "microbe",
        "gut microbiome diversity": "microbe",

        "igf-1": "hourglass",
        "growth hormone": "hourglass",
        "nad+": "hourglass",
        "telomere length": "hourglass",
        "advanced glycation end products": "hourglass",
        "biological age": "hourglass",

        "prealbumin": "fork.knife",

        // Protein Status
        // Bone Health
        "parathyroid hormone": "cross.case.fill",

        // Urine
        "urinalysis": "drop.fill",
        "protein (urine)": "drop.fill",
        "glucose (urine)": "drop.fill",
        "ketones": "drop.fill",
        "specific gravity": "drop.fill",

        // MARK: - Biometric / Wearable

        "heart rate (daily avg)": "heart.fill",
        "blood oxygen": "lungs.fill",
        "respiratory rate": "lungs.fill",
        "heart rate variability": "waveform.path.ecg",
        "resting heart rate": "heart.fill",
        "vo2 max": "lungs.fill",
        "sleep duration": "bed.double.fill",
        "deep sleep %": "bed.double.fill",
        "rem sleep %": "bed.double.fill",
        "steps": "figure.walk",
        "active calories": "flame.fill",
        "cardio load": "bolt.heart.fill",
        "water intake": "drop.fill",
        "sleep score": "bed.double.fill",
        "recovery score": "heart.fill",
        "strain score": "flame.fill",
        "stress score": "brain.head.profile",

        // MARK: - Nutrition
        // (calcium/iron/magnesium/potassium/sodium/zinc/copper/selenium and the
        //  shared vitamins are already mapped under Clinical above.)

        "energy in": "flame.fill",
        "protein": "fork.knife",
        "carbohydrates": "fork.knife",
        "fiber": "leaf.fill",
        "sugar": "cube.fill",
        "fat": "drop.fill",
        "saturated fat": "drop.fill",
        "trans fat": "drop.fill",
        "unsaturated fat": "drop.fill",
        "polyunsaturated fat": "drop.fill",
        "monounsaturated fat": "drop.fill",
        "omega-3": "fish",
        "omega-6": "fish",
        "cholesterol": "heart.fill",
        "manganese": "pills.fill",
        "iodine": "pills.fill",
        "phosphorus": "pills.fill",
        "vitamin c": "pills.fill",
        "thiamin (b1)": "pills.fill",
        "riboflavin (b2)": "pills.fill",
        "niacin (b3)": "pills.fill",
        "vitamin b6": "pills.fill",
        "biotin (b7)": "pills.fill",
        "folate (b9)": "pills.fill",
    ]
}
