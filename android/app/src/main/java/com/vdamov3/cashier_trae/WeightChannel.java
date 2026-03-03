package com.vdamov3.cashier_trae;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import com.weight.serialport.SerialListener;
import com.weight.serialport.SerialManager;
import com.weight.serialport.SerialPortConfig;
import com.weight.serialport.sdk.data.WeightBean;
import com.weight.serialport.sdk.until.SerialMessageUtil;

import java.io.ByteArrayOutputStream;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * 称重通道 — 通过 serialport AAR 读取串口称重数据，经 EventChannel 推送到 Flutter。
 * 协议：16字节定长帧
 *   [0]  0x01 SOH
 *   [1]  0x02 STX
 *   [2]  状态字符: 'S'=稳定 'U'=不稳定 'F'=溢出/未归零
 *   [3]  符号: '+'或'-'
 *   [4~9]  重量ASCII字符串，6位，如"00.260"（单位kg）
 *   [10~11] 单位"kg"
 *   [12]   BCC校验
 *   [13]  0x03 ETX
 *   [14]  0x04 EOT
 *   [15]  状态2: Bit4=零点 Bit5=去皮模式 Bit6=溢出
 */
public class WeightChannel implements MethodChannel.MethodCallHandler,
        EventChannel.StreamHandler, SerialListener {

    private static final String TAG = "WeightChannel";
    private EventChannel.EventSink eventSink;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    // 字节缓冲区，处理串口拆包
    private final ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream();

    // ── MethodChannel ────────────────────────────────────────
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "open": {
                String path = call.argument("path");
                Integer rate = call.argument("rate");
                if (path == null) path = "/dev/ttyS4";
                if (rate == null) rate = 9600;

                Log.d(TAG, "open() path=" + path + " rate=" + rate);
                byteBuffer.reset();
                SerialPortConfig.initSerial(path, rate, 0, 8, 1);
                SerialManager.getInstance().addSerialListener(this);
                boolean ok = SerialManager.getInstance().openSerialPort();
                Log.d(TAG, "openSerialPort() result=" + ok);
                result.success(ok);
                break;
            }
            case "close":
                Log.d(TAG, "close()");
                SerialManager.getInstance().closeSerialPort();
                SerialManager.getInstance().removeSerialListener(this);
                byteBuffer.reset();
                result.success(true);
                break;

            case "tare": {
                byte[] cmd = SerialMessageUtil.getInstance().setting_remove_peel();
                boolean sent = SerialManager.getInstance().send(cmd);
                Log.d(TAG, "tare sent=" + sent);
                result.success(sent);
                break;
            }
            case "zero": {
                byte[] cmd = SerialMessageUtil.getInstance().setting_zero();
                boolean sent = SerialManager.getInstance().send(cmd);
                Log.d(TAG, "zero sent=" + sent);
                result.success(sent);
                break;
            }
            case "requestWeight": {
                byte[] cmd = SerialMessageUtil.getInstance().send_weight();
                boolean sent = SerialManager.getInstance().send(cmd);
                Log.d(TAG, "requestWeight sent=" + sent);
                result.success(sent);
                break;
            }
            default:
                result.notImplemented();
        }
    }

    // ── EventChannel ─────────────────────────────────────────
    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        eventSink = null;
    }

    // ── SerialListener ───────────────────────────────────────
    @Override
    public void onDataReceived(byte[] buffer, int size, WeightBean weightBean, String hexStr) {
        // 拼接到缓冲区
        byteBuffer.write(buffer, 0, size);
        byte[] accumulated = byteBuffer.toByteArray();
        byteBuffer.reset();

        // 在缓冲区中扫描完整的16字节帧
        int i = 0;
        while (i <= accumulated.length - 16) {
            // 帧头：0x01 0x02；帧尾：[13]=0x03 [14]=0x04
            if ((accumulated[i] & 0xFF) == 0x01
                    && (accumulated[i + 1] & 0xFF) == 0x02
                    && (accumulated[i + 13] & 0xFF) == 0x03
                    && (accumulated[i + 14] & 0xFF) == 0x04) {
                byte[] packet = Arrays.copyOfRange(accumulated, i, i + 16);
                emitPacket(packet);
                i += 16;
            } else {
                i++;
            }
        }

        // 剩余不足一帧的字节留待下次处理
        if (i < accumulated.length) {
            byteBuffer.write(accumulated, i, accumulated.length - i);
        }
    }

    private void emitPacket(byte[] p) {
        // p[2]  : 状态 'S'/'U'/'F'
        // p[3]  : 符号 '+'/'-'
        // p[4~9]: 重量字符串 6字节 ASCII
        // p[12] : BCC (忽略校验，直接解析)
        // p[15] : 状态2

        char state1 = (char) (p[2] & 0xFF);
        boolean isPlus = (p[3] & 0xFF) != '-';
        String weightStr = new String(p, 4, 6).trim();

        double kg = 0.0;
        boolean valid = false;
        boolean stable = state1 == 'S';

        if (state1 != 'F') { // 'F' = 溢出/未归零
            try {
                kg = Double.parseDouble(weightStr) * (isPlus ? 1.0 : -1.0);
                valid = true;
            } catch (NumberFormatException e) {
                Log.w(TAG, "weight parse failed: [" + weightStr + "]");
            }
        }

        // 状态2 Bit4=零点
        int state2 = p[15] & 0xFF;
        boolean isZero = ((state2 >> 4) & 1) == 1;

        // 构造十六进制字符串用于日志
        StringBuilder sb = new StringBuilder();
        for (byte b : p) sb.append(String.format("%02X", b & 0xFF));
        Log.d(TAG, "packet=" + sb + " state1=" + state1 + " kg=" + kg + " stable=" + stable + " isZero=" + isZero);

        final double fKg = kg;
        final boolean fStable = stable;
        final boolean fValid = valid;
        final String fRaw = sb.toString();

        mainHandler.post(() -> {
            if (eventSink == null) return;
            Map<String, Object> data = new HashMap<>();
            data.put("raw", fRaw);
            data.put("kg", fKg);
            data.put("stable", fStable);
            data.put("valid", fValid);
            eventSink.success(data);
        });
    }

    @Override
    public void openSerialError(String path, int errorCode) {
        Log.e(TAG, "Serial open error: " + path + " code=" + errorCode);
        mainHandler.post(() -> {
            if (eventSink != null) {
                eventSink.error("SERIAL_ERROR", "Failed to open " + path, errorCode);
            }
        });
    }
}
