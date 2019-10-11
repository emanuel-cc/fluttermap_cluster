import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:fluster/fluster.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttermap_cluster/helpers/map_marker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapHelper{
  static Future<BitmapDescriptor> getMarkerImageFromUrl(
    String url, {
    int targetWidth,
  }
  )async{
    assert(url != null);
    final File markerImageFile = await DefaultCacheManager().getSingleFile(url);
    Uint8List markerImageBytes = await markerImageFile.readAsBytes();
    if (targetWidth != null) {
      markerImageBytes = await _resizeImageBytes(
        markerImageBytes,
        targetWidth,
      );
    }
    return BitmapDescriptor.fromBytes(markerImageBytes);

  }

  static Future<Uint8List> _resizeImageBytes(
    Uint8List imageBytes,
    int targetWidth,
  )async{
    assert(imageBytes != null);
    assert(targetWidth != null);
    final Codec imageCodec = await instantiateImageCodec(
      imageBytes,
      targetWidth: targetWidth,
    );
    final FrameInfo frameInfo = await imageCodec.getNextFrame();
    final ByteData byteData = await frameInfo.image.toByteData(
      format: ImageByteFormat.png,
    );
    return byteData.buffer.asUint8List();
  }

  static Future<Fluster<MapMarker>> initClusterManager(
    List<MapMarker> markers,
    int minZoom,
    int maxZoom,
    String clusterImageUrl,
  )async{
    assert(markers != null);
    assert(minZoom != null);
    assert(maxZoom != null);
    assert(clusterImageUrl != null);

    final BitmapDescriptor clusterImage =
        await MapHelper.getMarkerImageFromUrl(clusterImageUrl);

    return Fluster<MapMarker>(
      minZoom: minZoom,
      maxZoom: maxZoom,
      radius: 150,
      extent: 2048,
      nodeSize: 64,
      points: markers,
      createCluster: (
        BaseCluster cluster,
        double lng,
        double lat,
      )=>MapMarker(
        id: cluster.id.toString(),
        position: LatLng(lat, lng),
        icon: clusterImage,
        isCluster: true,
        clusterId: cluster.id,
        pointsSize: cluster.pointsSize,
        childMarkerId: cluster.childMarkerId,
      ),
    );
  }

  static List<Marker> getClusterMarkers(
    Fluster<MapMarker> clusterManager,
    double currentZoom,
  ){
    assert(currentZoom != null);
    if (clusterManager == null) return [];
    return clusterManager
      .clusters([-180, -85, 180, 85], currentZoom.toInt())
      .map((cluster) => cluster.toMarker())
      .toList();
  }
}