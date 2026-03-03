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

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * 称重通道 — 通过 serialport AAR 读取串口称重数据，经 EventChannel 推送到 Flutter。
 * MethodChannel: "cashier/weight"
 * EventChannel:  "cashier/weight/events"
 */
public class WeightChannel implements MethodChannel.MethodCallHandler,
        EventChannel.StreamHandler, SerialListener {

    private static final String TAG = "WeightChannel";
    private EventChannel.EventSink eventSink;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    // ── MethodChannel ────────────────────────────────────────
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "open": {
                String path = call.argument("path");
                Integer rate = call.argument("rate");
                if (path == null) path = "/dev/ttyS3";
                if (rate == null) rate = 9600;

                Log.d(TAG, "open() path=" + path + " rate=" + rate);
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
    @SuppressWarnings("rawtypes")
    public void onDataReceived(byte[] buffer, int size, WeightBean weightBean, String hex) {
        Log.d(TAG, "onDataReceived hex=[" + hex + "] size=" + size);

        mainHandler.post(() -> {
            if (eventSink == null) return;

            Object dataObj = weightBean.data;
            String raw = dataObj != null ? dataObj.toString().trim() : "0";

            double kg = 0.0;
            boolean stable = false;
            boolean valid = false;

            // ── 方案1：反射提取 netWeight / isStable ─────────────
            // WeightBean.data 是 WeightInfo 对象时走这里
            if (dataObj != null) {
                try {
                    kg = getDoubleField(dataObj, "netWeight");
                    stable = getBoolField(dataObj, "isStable");
                    valid = true;
                    Log.d(TAG, "weight[reflect] netWeight=" + kg + " isStable=" + stable);
                } catch (Exception e1) {

                    // ── 方案2：从 toString() 用更为宽泛的正则解析 ──────────────
                    try {
                        Matcher mKg = Pattern.compile("netWeight[^\\d\\.\\-]+(-?\\d+\\.?\\d*)").matcher(raw);
                        if (mKg.find()) {
                            kg = Double.parseDouble(mKg.group(1));
                            valid = true;
                        } else {
                            // 有些秤可能叫 weight
                            Matcher mKg2 = Pattern.compile("weight[^\\d\\.\\-]+(-?\\d+\\.?\\d*)").matcher(raw);
                            if (mKg2.find()) {
                                kg = Double.parseDouble(mKg2.group(1));
                                valid = true;
                            }
                        }
                        Matcher mStable = Pattern.compile("isStable[^a-zA-Z]+(true|false)").matcher(raw);
                        if (mStable.find()) {
                            stable = "true".equals(mStable.group(1));
                        } else {
                            // 有些秤可能叫 stable
                            Matcher mStable2 = Pattern.compile("stable[^a-zA-Z]+(true|false)").matcher(raw);
                            if (mStable2.find()) {
                                stable = "true".equals(mStable2.group(1));
                            }
                        }
                        if (valid) {
                            Log.d(TAG, "weight[regex] netWeight=" + kg + " isStable=" + stable);
                        } else {
                            Log.w(TAG, "weight[regex] no netWeight found, raw=" + raw);
                        }
                    } catch (Exception e2) {
                        Log.w(TAG, "weight[regex] failed: " + e2.getMessage());
                    }

                    // ── 方案3：data 本身就是数字 ──────────────────────
                    if (!valid && dataObj instanceof Number) {
                        kg = ((Number) dataObj).doubleValue();
                        valid = kg > 0;
                        Log.d(TAG, "weight[number] kg=" + kg);
                    }
                }
            }

            Map<String, Object> data = new HashMap<>();
            data.put("raw", raw);
            data.put("kg", kg);
            data.put("stable", stable);
            data.put("valid", valid);
            eventSink.success(data);
        });
    }

    private static double getDoubleField(Object obj, String name) throws Exception {
        Field f = findField(obj.getClass(), name);
        f.setAccessible(true);
        Object val = f.get(obj);
        if (val instanceof Number) return ((Number) val).doubleValue();
        throw new NoSuchFieldException(name + " is not a Number");
    }

    private static boolean getBoolField(Object obj, String name) throws Exception {
        Field f = findField(obj.getClass(), name);
        f.setAccessible(true);
        Object val = f.get(obj);
        return Boolean.TRUE.equals(val);
    }

    /** 递归向父类查找字段，处理继承链 */
    private static Field findField(Class<?> clz, String name) throws NoSuchFieldException {
        while (clz != null && clz != Object.class) {
            try { return clz.getDeclaredField(name); } catch (NoSuchFieldException ignore) {}
            clz = clz.getSuperclass();
        }
        throw new NoSuchFieldException(name);
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
