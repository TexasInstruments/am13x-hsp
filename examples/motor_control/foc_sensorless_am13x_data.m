% =============================================================================
% foc_sensorless_am13x_data.m
%
% Motor control parameter script for Simulink FOC model.
%
% Hardware:
%   MCU     : Texas Instruments AM13x (AM13X LaunchPad)
%   Motor   : Teknic M-2310P-LN-04K PMSM
%   Inverter: DRV8323RH gate driver with 3-shunt current sensing
%
% Usage:
%   Run this script before opening or simulating the Simulink model.
%   All workspace variables are consumed directly by the model blocks.
%
% Dependencies:
%   Motor Control Blockset (mcb) toolbox
% =============================================================================

%  Copyright (C) 2026 Texas Instruments Incorporated
%
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions
%  are met:
%
%    Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
%
%    Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the
%    distribution.
%
%    Neither the name of Texas Instruments Incorporated nor the names of
%    its contributors may be used to endorse or promote products derived
%    from this software without specific prior written permission.
%
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
%  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
%  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
%  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
%  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
%  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
%  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
%  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
%  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
%  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%% ============================================================
%  1. PWM AND SAMPLE TIMES
% =============================================================

PWM_frequency       = 20e3;             % Hz  - PWM switching frequency
T_pwm               = 1 / PWM_frequency; % s   - PWM period

% Control loop sample times
Ts                  = T_pwm;            % s   - Current loop sample time (= PWM period)
Ts_speed            = 10 * Ts;          % s   - Speed loop sample time (10x slower)

% Simulation-only sample times (not used in code generation)
Ts_simulink         = T_pwm / 2;        % s   - Simulink solver step
Ts_motor            = T_pwm / 2;        % s   - PMSM plant model step
Ts_inverter         = T_pwm / 2;        % s   - Inverter model step

% Open-loop startup timing
Speed_openLoop_PU   = 0.2;             % PU  - Open-loop reference speed


% Closed-loop enable time (0 = immediate after open-loop)
Ts_enClosedLoop     = 0;

% Speed step time for reference profiling
Tclosedloop_stepTime         = 5;               % s   - Time of speed step in simulation to switch to closed loop
Tspeedchange_stepTime        = 7;               % s   - Time of speed step in simulation to increase speed

%% ============================================================
%  2. DATA TYPE
% =============================================================

% Single precision floating point for code generation on AM13x Cortex-M33
% AM13x has hardware FPU (FPv5-SP-D16) — single precision is native
dataType            = 'single';

%% ============================================================
%  3. MOTOR PARAMETERS - Teknic M-2310P-LN-04K
% =============================================================
% Uses Motor Control Blockset built-in parameter set.
% Reference: https://www.teknic.com/model-info/M-2310P/

pmsm                = mcb.getPMSMParameters('Teknic2310P');

% Nominal values from mcb (shown for reference, do not uncomment unless overriding):
% pmsm.Rs           = 0.394;       % Ohm  - Stator resistance
% pmsm.Ld           = 190.4e-6;    % H    - D-axis inductance
% pmsm.Lq           = 190.4e-6;    % H    - Q-axis inductance (surface PMSM: Ld = Lq)
% pmsm.FluxPM       = 0.03994;     % Wb   - Permanent magnet flux linkage
% pmsm.N_base       = 3000;        % RPM  - Base (rated) speed
% pmsm.I_rated      = 2.2;         % A    - Rated phase current (peak)

% Voltage boost for open-loop startup (PU, applied to V/f profile)
pmsm.V_boost        = 0.2;          % PU

% Observer selection: 'EEMF' = Extended EMF sensorless, 'Encoder' = encoder feedback
sensor              = 'EEMF';

%% ============================================================
%  4. TARGET PARAMETERS - TI AM13x (AM13X)
% =============================================================
% Manual definition — mcb.getProcessorParameters not used (AM13x not in MCB database)

target.model            = 'AM13E230x';      % TI LaunchPad E2 evaluation board
target.CPU_frequency    = 200e6;            % Hz  - Cortex-M33 core clock
target.PWM_frequency    = PWM_frequency;    % Hz  - Must match section 1
target.PWM_Counter_Period = target.CPU_frequency / (2 * target.PWM_frequency);
                                            %      = 5000 counts (up-down counter)
target.ADC_Vref         = 3.3;             % V   - ADC reference voltage
target.ADC_MaxCount     = 4095;            %      - 12-bit ADC full scale
target.SCI_baud_rate    = 5e6;             % bps - UART baud rate for host comms
% API: serialportlist
% Use serialportlist this API to get all available serial port on the host
target.comport          = 'COM7'; % Update before connecting e.g. 'COM9'

%% ============================================================
%  5. INVERTER PARAMETERS - DRV8323RH with 3-Shunt Sensing
% =============================================================
% BoostXL-DRV8323RH evaluation module connected to AM13x LaunchPad

% Start from closest MCB template then override for DRV8323RH
inverter                = mcb.getInverterParameters('BoostXL-DRV8305');

inverter.model          = 'BoostXL-DRV8323RH';
inverter.V_dc           = 24;           % V    - DC bus voltage
inverter.I_trip         = 10;           % A    - Hardware overcurrent trip threshold

% Power stage
inverter.Rds_on         = 0.002;        % Ohm  - FET Rds(on) per switch (DRV8323RH)

% Current sensing — 3-shunt via internal current sense amplifier (CSA)
inverter.Rshunt         = 0.007;        % Ohm  - Phase shunt resistor value
inverter.ADCGain        = 20;           % V/V  - CSA gain (DRV8323RH SPI-programmable)
%
% DRV8323RH CSA gain options (set via SPI CSAGAIN bits):
%   5  V/V  → low sensitivity, high current range
%   10 V/V  → standard
%   20 V/V  → default (MCU Hi-Z / floating GAIN pin)
%   40 V/V  → high sensitivity, low current range
%
% Current sense output voltage:
%   V_SOx = V_REF - (I_phase × Rshunt × ADCGain)
%   DRV8323RH uses inverting amplifier — positive phase current → voltage below V_REF

inverter.invertingAmp   = -1;           %      - Inverting CSA: positive I → negative ADC delta
inverter.ISenseVref     = 3.3;          % V    - CSA output reference (mid-supply = Vcc/2 ~ 1.65V but ADC ref = 3.3V)
inverter.ISenseVoltPerAmp = inverter.Rshunt * inverter.ADCGain;   % V/A = 0.14 V/A
inverter.ISenseMax      = inverter.ISenseVref / (2 * inverter.ISenseVoltPerAmp); % A - peak measurable current

% Enable pin polarity
inverter.EnableLogic    = 1;            %      - Active high (EN_GATE pin on DRV8323RH)

% ADC offset counts for zero-current calibration (midpoint of 12-bit = 2048)
inverter.CtSensAOffset  = 2048;         % ADC counts - Phase A zero-current offset
inverter.CtSensBOffset  = 2048;         % ADC counts - Phase B zero-current offset
inverter.CtSensCOffset  = 2048;         % ADC counts - Phase C zero-current offset

% Auto-calibration limits (used by offset calibration subsystem in model)
inverter.CtSensOffsetMax = 2048;        % ADC counts - Upper bound for valid offset
inverter.CtSensOffsetMin = 2048;        % ADC counts - Lower bound for valid offset

%% ============================================================
%  6. DERIVED MOTOR CHARACTERISTICS
% =============================================================

% Recalculate base speed from motor and inverter DC bus voltage
pmsm.N_base             = mcb.getMotorBaseSpeed(pmsm, inverter); % RPM
Speed_openLoop_RPM   = Speed_openLoop_PU*pmsm.N_base; % Open Loop speed in RPM

% Display rated torque estimate
mcb.PMSMRatedTorque(pmsm, inverter);

%% ============================================================
%  7. PER-UNIT SYSTEM AND PI CONTROLLER GAINS
% =============================================================

% Base values for per-unit normalisation
PU_System = mcb.getPUSystemParameters(pmsm, inverter);

% PI gains for current and speed controllers
% Tuned for:
%   Current loop bandwidth  ≈ 1 / (10 × Ts)  (auto-tuned by MCB)
%   Speed loop bandwidth    ≈ 1 / (10 × Ts_speed)
PI_params = mcb.getPIControllerParameters(pmsm, inverter, PU_System, T_pwm, Ts, Ts_speed);

%% ============================================================
%  8. SIMULATION DELAYS (used by Simulink simulation only)
% =============================================================

PI_params.delay_Currents = int32(Ts / Ts_simulink);        % 2 steps
PI_params.delay_Position = int32(Ts / Ts_simulink);        % 2 steps
PI_params.delay_Speed    = int32(Ts_speed / Ts_simulink);  % 20 steps

% IIR filter delay contribution to speed loop (in speed loop periods)
PI_params.delay_Speed1   = (PI_params.delay_IIR + 0.5 * Ts) / Ts_speed;

% Copy Iq gains from current controller (surface PMSM: Id loop = Iq loop)
PI_params.Ki_iq          = PI_params.Ki_i;
PI_params.Kp_iq          = PI_params.Kp_i;

% Alias for BLDC-compatible model blocks (surface PMSM = BLDC equivalent)
bldc = pmsm;

%% ============================================================
%  9. SENSORLESS OBSERVER - Sliding Mode Observer (SMO)
% =============================================================

% SMO parameters computed from motor electrical model and sample time
smo = mcb.computeSMOParameters(pmsm, Ts, PU_System);

%% ============================================================
%  10. OPEN-LOOP TO CLOSED-LOOP TRANSITION (Id RAMP-DOWN)
% =============================================================
% After open-loop startup, Id reference is ramped from Id_init down to 0
% over T_ramp_duration seconds to avoid torque disturbance on transition.

T_ramp_rate         = Ts_speed;         % s    - Ramp updated every speed loop tick
T_ramp_duration     = 0.2;             % s    - Total ramp-down duration
N_ramp_steps        = T_ramp_duration / T_ramp_rate; % steps = 400

Id_init_assumed     = 0.1;             % PU   - Initial Id at transition point
RAMP_STEP_SIZE      = Id_init_assumed / N_ramp_steps; % PU/step = 2.5e-4

%% ============================================================
%  11. DISPLAY SUMMARY
% =============================================================

fprintf('\n--- Motor: %s ---\n', 'Teknic M-2310P');
fprintf('  Rs      = %.4f Ohm\n',  pmsm.Rs);
fprintf('  Ld/Lq   = %.2f uH\n',   pmsm.Ld * 1e6);
fprintf('  FluxPM  = %.5f Wb\n',   pmsm.FluxPM);
fprintf('  N_base  = %.0f RPM\n',  pmsm.N_base);
fprintf('  I_rated = %.1f A\n',    pmsm.I_rated);

fprintf('\n--- Inverter: DRV8323RH ---\n');
fprintf('  V_dc          = %.1f V\n',   inverter.V_dc);
fprintf('  Rshunt        = %.4f Ohm\n', inverter.Rshunt);
fprintf('  ADCGain       = %.0f V/V\n', inverter.ADCGain);
fprintf('  ISenseVoltPerAmp = %.4f V/A\n', inverter.ISenseVoltPerAmp);
fprintf('  ISenseMax     = %.2f A\n',   inverter.ISenseMax);

fprintf('\n--- Target: AM13E230X ---\n');
fprintf('  CPU           = %.0f MHz\n', target.CPU_frequency / 1e6);
fprintf('  PWM_Period    = %.0f counts\n', target.PWM_Counter_Period);
fprintf('  ADC_Vref      = %.1f V\n',   target.ADC_Vref);
fprintf('  UART_baud     = %.0f Mbps\n', target.SCI_baud_rate / 1e6);

fprintf('\n--- PU System ---\n');
disp(PU_System);