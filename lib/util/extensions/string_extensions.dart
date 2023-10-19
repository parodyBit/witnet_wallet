extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${this.substring(1).toLowerCase()}';
  }

  String cropMiddle(int length) {
    if (this.length > length) {
      var leftSizeLengh = ((length - 3) / 2).floor();
      var rightSizeLength = this.length - leftSizeLengh;
      return '${this.substring(0, leftSizeLengh)}...${this.substring(rightSizeLength)}';
    } else {
      return '';
    }
  }

  String fromPascalCaseToTitle() {
    final result = this.split(RegExp('(?=[A-Z])'));
    return result.join(' ').toLowerCase().capitalize();
  }

  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.capitalize())
      .join(' ');

  bool toBoolean() => this == 'true' || this == 'True';
}
