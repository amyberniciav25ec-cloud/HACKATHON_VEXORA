# ECG Insight – ECG Signal Abnormality Analysis

## Overview
ECG Insight analyzes ECG signals to identify unusual waveform patterns and compare heartbeat characteristics.

## Features
- ECG signal visualization
- Noise reduction using a moving average filter
- R-peak detection
- Heart rate (BPM) estimation
- RR interval analysis
- Preliminary unusual-pattern flagging

## Technologies Used
- MATLAB R2026b
- MATLAB signal-processing algorithms
- Simulink (planned integration)

## Workflow
ECG Input → Noise Filtering → R-Peak Detection → Feature Extraction → Pattern Analysis → Results

## Project Files
- `real_ecg_analysis.m` – MATLAB analysis script
- `ECG_Abnormality_Analysis.slx` – Simulink model

## Current Status
The prototype demonstrates ECG signal filtering, visualization, and basic heartbeat-pattern analysis. Testing with real ECG recordings and further validation are ongoing.

## Future Scope
- Analyze real ECG datasets
- Improve abnormal-pattern detection
- Integrate the workflow into Simulink
- Develop a user-friendly interface

## Disclaimer
This project is for educational and research purposes only. It is not a medical diagnostic tool.
