class FormatTime{
  static  String formatTime(Duration duration){
    String twoDigits(int n)=> n.toString().padLeft(2,"0");
    final hours = twoDigits(duration.inHours);
    final mins = twoDigits(duration.inMinutes);
    final secs = twoDigits(duration.inSeconds);

    return [
      if(duration.inHours >0) hours,mins,secs
    ].join(":");
  }
}