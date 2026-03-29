/**

 * 从 app_icon_foreground_src.svg 与 background.png（1024×1024）生成分层前景，并同步到 AppScope / entry。

 * 依赖：npm install sharp（仓库根目录）

 */

const fs = require('fs');

const path = require('path');

const sharp = require('sharp');



const root = path.resolve(__dirname, '..');

const baseMedia = path.join(root, 'AppScope/resources/base/media');

const svgPath = path.join(baseMedia, 'app_icon_foreground_src.svg');

const bgPath = path.join(baseMedia, 'background.png');



async function main() {

  const svg = fs.readFileSync(svgPath);

  const bgBuf = fs.readFileSync(bgPath);



  const fg1024 = await sharp(svg).resize(1024, 1024).png().toBuffer();

  const bg1024 = await sharp(bgBuf).resize(1024, 1024).png().toBuffer();



  fs.writeFileSync(path.join(baseMedia, 'background.png'), bg1024);

  fs.writeFileSync(path.join(baseMedia, 'foreground.png'), fg1024);

  fs.writeFileSync(

    path.join(root, 'entry/src/main/resources/base/media/background.png'),

    bg1024

  );

  fs.writeFileSync(

    path.join(root, 'entry/src/main/resources/base/media/foreground.png'),

    fg1024

  );



  console.log('layered icon foreground/background (1024) regenerated.');

}



main().catch((e) => {

  console.error(e);

  process.exit(1);

});


