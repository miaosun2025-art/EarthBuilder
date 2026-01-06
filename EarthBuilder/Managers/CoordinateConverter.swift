//
//  CoordinateConverter.swift
//  EarthBuilder
//
//  坐标转换工具
//  解决中国 GPS 偏移问题：WGS-84 → GCJ-02
//

import Foundation
import CoreLocation

/// 坐标转换工具类
/// 用于解决中国地图坐标系偏移问题
enum CoordinateConverter {

    // MARK: - Constants

    /// 长半轴
    private static let a: Double = 6378245.0

    /// 扁率
    private static let ee: Double = 0.00669342162296594323

    /// 圆周率
    private static let pi: Double = 3.1415926535897932384626

    // MARK: - Public Methods

    /// WGS-84 转 GCJ-02（火星坐标系）
    /// - Parameter wgs84: WGS-84 坐标（GPS 原始坐标）
    /// - Returns: GCJ-02 坐标（中国地图使用的坐标）
    static func wgs84ToGcj02(_ wgs84: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // 判断是否在中国境内
        if !isInChina(wgs84) {
            // 不在中国境内，不需要转换
            return wgs84
        }

        // 计算偏移量
        let (dLat, dLon) = delta(wgs84.latitude, wgs84.longitude)

        // 返回转换后的坐标
        return CLLocationCoordinate2D(
            latitude: wgs84.latitude + dLat,
            longitude: wgs84.longitude + dLon
        )
    }

    /// 批量转换坐标数组
    /// - Parameter wgs84Coordinates: WGS-84 坐标数组
    /// - Returns: GCJ-02 坐标数组
    static func wgs84ToGcj02(_ wgs84Coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        return wgs84Coordinates.map { wgs84ToGcj02($0) }
    }

    // MARK: - Private Methods

    /// 判断坐标是否在中国境内
    /// - Parameter coordinate: 待判断的坐标
    /// - Returns: 是否在中国境内
    private static func isInChina(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let lat = coordinate.latitude
        let lon = coordinate.longitude

        // 中国境内范围：纬度 0.8293 ~ 55.8271，经度 72.004 ~ 137.8347
        return lat >= 0.8293 && lat <= 55.8271 && lon >= 72.004 && lon <= 137.8347
    }

    /// 计算坐标偏移量
    /// - Parameters:
    ///   - lat: 纬度
    ///   - lon: 经度
    /// - Returns: (纬度偏移, 经度偏移)
    private static func delta(_ lat: Double, _ lon: Double) -> (Double, Double) {
        let dLat = transformLat(lon - 105.0, lat - 35.0)
        let dLon = transformLon(lon - 105.0, lat - 35.0)

        let radLat = lat / 180.0 * pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)

        let deltaLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi)
        let deltaLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi)

        return (deltaLat, deltaLon)
    }

    /// 纬度转换
    /// - Parameters:
    ///   - x: 经度偏移
    ///   - y: 纬度偏移
    /// - Returns: 转换后的纬度偏移
    private static func transformLat(_ x: Double, _ y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y
        ret += 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * pi) + 320.0 * sin(y * pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    /// 经度转换
    /// - Parameters:
    ///   - x: 经度偏移
    ///   - y: 纬度偏移
    /// - Returns: 转换后的经度偏移
    private static func transformLon(_ x: Double, _ y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y
        ret += 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0
        return ret
    }
}
