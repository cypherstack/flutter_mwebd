class Status {
  final int blockHeaderHeight;
  final int mwebHeaderHeight;
  final int mwebUtxosHeight;
  final int blockTime;

  Status({
    required this.blockHeaderHeight,
    required this.mwebHeaderHeight,
    required this.mwebUtxosHeight,
    required this.blockTime,
  });

  @override
  String toString() {
    return 'Status('
        'blockHeaderHeight: $blockHeaderHeight, '
        'mwebHeaderHeight: $mwebHeaderHeight, '
        'mwebUtxosHeight: $mwebUtxosHeight, '
        'blockTime: $blockTime'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Status &&
          blockHeaderHeight == other.blockHeaderHeight &&
          mwebHeaderHeight == other.mwebHeaderHeight &&
          mwebUtxosHeight == other.mwebUtxosHeight &&
          blockTime == other.blockTime;

  @override
  int get hashCode => Object.hash(
    blockHeaderHeight,
    mwebHeaderHeight,
    mwebUtxosHeight,
    blockTime,
  );
}
