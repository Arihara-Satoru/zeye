// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CameraAdapter extends TypeAdapter<Camera> {
  @override
  final int typeId = 0;

  @override
  Camera read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Camera(
      name: fields[0] as String,
      url: fields[1] as String,
      username: fields[2] as String,
      password: fields[3] as String,
      ipAddress: fields[4] as String,
      port: fields[5] as String,
      isOnline: fields[6] as bool,
      snapshotUrl: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Camera obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.ipAddress)
      ..writeByte(5)
      ..write(obj.port)
      ..writeByte(6)
      ..write(obj.isOnline)
      ..writeByte(7)
      ..write(obj.snapshotUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
