import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Mapa único de iconos (Phosphor, estilo regular). Ver sistema de diseño §5.
///
/// El estilo relleno (`fill`) se reserva para el destino activo de la navegación.
abstract final class AppIcons {
  // Navegación
  static const IconData home = PhosphorIconsRegular.house;
  static const IconData homeActive = PhosphorIconsFill.house;
  static const IconData cycle = PhosphorIconsRegular.plant;
  static const IconData cycleActive = PhosphorIconsFill.plant;
  static const IconData plot = PhosphorIconsRegular.mapTrifold;
  static const IconData plotActive = PhosphorIconsFill.mapTrifold;
  static const IconData history = PhosphorIconsRegular.clockCounterClockwise;
  static const IconData historyActive = PhosphorIconsFill.clockCounterClockwise;
  static const IconData more = PhosphorIconsRegular.dotsThreeOutline;
  static const IconData moreActive = PhosphorIconsFill.dotsThreeOutline;

  // Conceptos del dominio
  static const IconData application = PhosphorIconsRegular.flask;
  static const IconData task = PhosphorIconsRegular.shovel;
  static const IconData pest = PhosphorIconsRegular.bug;
  static const IconData disease = PhosphorIconsRegular.leaf;
  static const IconData climate = PhosphorIconsRegular.cloudLightning;
  static const IconData water = PhosphorIconsRegular.drop;
  static const IconData harvest = PhosphorIconsRegular.basket;
  static const IconData flower = PhosphorIconsRegular.flower;
  static const IconData photo = PhosphorIconsRegular.camera;
  static const IconData gallery = PhosphorIconsRegular.images;
  static const IconData microphone = PhosphorIconsRegular.microphone;
  static const IconData stop = PhosphorIconsRegular.stop;
  static const IconData reminder = PhosphorIconsRegular.bellRinging;
  static const IconData costs = PhosphorIconsRegular.wallet;
  static const IconData sale = PhosphorIconsRegular.handCoins;
  static const IconData coins = PhosphorIconsRegular.coins;
  static const IconData receipt = PhosphorIconsRegular.receipt;
  static const IconData share = PhosphorIconsRegular.shareNetwork;
  static const IconData pdf = PhosphorIconsRegular.filePdf;
  static const IconData whatsapp = PhosphorIconsRegular.whatsappLogo;
  static const IconData offline = PhosphorIconsRegular.cloudSlash;
  static const IconData location = PhosphorIconsRegular.mapPin;
  static const IconData calendar = PhosphorIconsRegular.calendarBlank;
  static const IconData clock = PhosphorIconsRegular.clock;
  static const IconData compare = PhosphorIconsRegular.arrowsLeftRight;
  static const IconData timeline = PhosphorIconsRegular.listBullets;
  static const IconData scales = PhosphorIconsRegular.scales;
  static const IconData ruler = PhosphorIconsRegular.ruler;
  static const IconData users = PhosphorIconsRegular.users;
  static const IconData truck = PhosphorIconsRegular.truck;
  static const IconData tractor = PhosphorIconsRegular.tractor;
  static const IconData package = PhosphorIconsRegular.package;
  static const IconData grains = PhosphorIconsRegular.grains;
  static const IconData scissors = PhosphorIconsRegular.scissors;
  static const IconData tree = PhosphorIconsRegular.tree;
  static const IconData waves = PhosphorIconsRegular.waves;
  static const IconData note = PhosphorIconsRegular.notePencil;
  static const IconData lightbulb = PhosphorIconsRegular.lightbulb;
  static const IconData book = PhosphorIconsRegular.bookOpen;
  static const IconData pottedPlant = PhosphorIconsRegular.pottedPlant;
  static const IconData sprayBottle = PhosphorIconsRegular.sprayBottle;
  static const IconData fire = PhosphorIconsRegular.fire;
  static const IconData hourglass = PhosphorIconsRegular.hourglass;
  static const IconData crosshair = PhosphorIconsRegular.crosshair;
  static const IconData palette = PhosphorIconsRegular.palette;
  static const IconData database = PhosphorIconsRegular.database;
  static const IconData money = PhosphorIconsRegular.money;
  static const IconData leaf = PhosphorIconsRegular.leaf;
  static const IconData export = PhosphorIconsRegular.export;
  static const IconData plus = PhosphorIconsRegular.plus;
  static const IconData filter = PhosphorIconsRegular.funnel;
  static const IconData incident = PhosphorIconsRegular.warning;
  static const IconData plant = PhosphorIconsRegular.plant;
  static const IconData bug = PhosphorIconsRegular.bug;

  // Clima al aplicar
  static const IconData sunny = PhosphorIconsRegular.sun;
  static const IconData cloudy = PhosphorIconsRegular.cloud;
  static const IconData wetSoil = PhosphorIconsRegular.dropHalf;
  static const IconData rainAfter = PhosphorIconsRegular.cloudRain;
  static const IconData wind = PhosphorIconsRegular.wind;
  static const IconData morning = PhosphorIconsRegular.sunHorizon;
  static const IconData noon = PhosphorIconsRegular.sun;
  static const IconData afternoon = PhosphorIconsRegular.sunDim;

  // Estados y veredictos
  static const IconData checkCircle = PhosphorIconsRegular.checkCircle;
  static const IconData minusCircle = PhosphorIconsRegular.minusCircle;
  static const IconData warning = PhosphorIconsRegular.warning;
  static const IconData info = PhosphorIconsRegular.info;
  static const IconData trendUp = PhosphorIconsRegular.trendUp;
  static const IconData trendDown = PhosphorIconsRegular.trendDown;
  static const IconData severityLow = PhosphorIconsRegular.cellSignalLow;
  static const IconData severityMedium = PhosphorIconsRegular.cellSignalMedium;
  static const IconData severityHigh = PhosphorIconsRegular.cellSignalFull;

  // Acciones genéricas
  static const IconData add = PhosphorIconsRegular.plus;
  static const IconData close = PhosphorIconsRegular.x;
  static const IconData check = PhosphorIconsRegular.check;
  static const IconData back = PhosphorIconsRegular.arrowLeft;
  static const IconData forward = PhosphorIconsRegular.caretRight;
  static const IconData expand = PhosphorIconsRegular.caretDown;
  static const IconData menu = PhosphorIconsRegular.dotsThreeVertical;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData delete = PhosphorIconsRegular.trash;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData settings = PhosphorIconsRegular.gear;
  static const IconData help = PhosphorIconsRegular.question;
  static const IconData chart = PhosphorIconsRegular.chartBar;
  static const IconData image = PhosphorIconsRegular.image;
  static const IconData sun = PhosphorIconsRegular.sun;
  static const IconData moon = PhosphorIconsRegular.moon;
  static const IconData system = PhosphorIconsRegular.circleHalf;
  static const IconData copy = PhosphorIconsRegular.copy;
  static const IconData folder = PhosphorIconsRegular.folder;
  static const IconData folderOpen = PhosphorIconsRegular.folderOpen;
  static const IconData restore = PhosphorIconsRegular.arrowCounterClockwise;
  static const IconData archive = PhosphorIconsRegular.archive;
  static const IconData upload = PhosphorIconsRegular.uploadSimple;
  static const IconData download = PhosphorIconsRegular.downloadSimple;
}

