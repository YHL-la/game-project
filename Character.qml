import QtQuick
import QtQuick.Controls
//管理焦点（键盘）
FocusScope {
    id: character
    width: 10
    height: 20
    // 血量
    property int blood:1
    //生命数量
    property int lives:3
    // 基础移动速度
    property real speed: 0
//最大速度
    property real maxspeed:10
    // 垂直速度，用于控制跳跃和下落
    property real verticalSpeed: 0

    // 重力加速度
    property real gravity: 0.5

    property real hSpeed: 0 // 实际水平速度
    property real moveAcceleration: 0.2 // 水平加速度


    // 跳跃参数
    property real jumpHoldAcceleration: -0.3 // 长按跳跃时的持续加速度
    property bool isJumpHeld: false          // 是否按住跳跃键
    // 跳跃初速度
    property real jumpSpeed: -8

    // 能否跳跃
    property bool canJump: true

    // 移动方向
    property bool movingLeft: false
    property bool movingRight: false
    property bool islefton: false
    property bool isrighton: false

    // 地面列表
      property var grounds: []
    // x: 0
    // y: 460
    property real containerWidth: 640
     property real containerHeight: 480

    // 追踪角色是否站在地面上
        property bool isOnGround: false

    // 可视化表示
    Rectangle {
        id: visual
        anchors.fill: parent
        color: character.movingLeft ? "lightblue" : (character.movingRight ? "darkblue" : "blue")
        width:10
        height:20
        focus: true
        //按键
        Keys.onPressed: {
            if (event.key === Qt.Key_A) {
                console.log(hSpeed)
                character.movingLeft = true

            }else if (event.key === Qt.Key_D) {
                console.log(hSpeed)
                character.movingRight = true

              }else if (event.key === Qt.Key_K && canJump) {
                // 触发跳跃
                verticalSpeed = jumpSpeed
                canJump = false // 防止空中连跳
                isJumpHeld=true
            }
        }

        Keys.onReleased: {
            if (event.key ===Qt.Key_A) {

                character.movingLeft = false
            } else if (event.key === Qt.Key_D) {

                character.movingRight = false
            }else if(event.key===Qt.Key_K){
                isJumpHeld=false
            }

        }
    }

    Timer {
        id: moveTimer
        interval: 12 // 120 FPS
        running: true
        repeat: true
        onTriggered: {
            var oldX = character.x
            var oldY = character.y

            if (movingLeft) {
                    // 左移加速
                    hSpeed = Math.max(hSpeed - moveAcceleration, -maxspeed)
                } else if (movingRight) {
                    // 右移加速
                    hSpeed = Math.min(hSpeed + moveAcceleration, maxspeed)
                } else {
                    // 新增：刹车效果（摩擦力）
                    if (hSpeed != 0) {
                        // 判断运动方向
                        var friction = moveAcceleration * 1.5 // 摩擦力比加速度大50%
                        if (hSpeed > 0) {
                            hSpeed = Math.max(hSpeed - friction, 0)
                        } else {
                            hSpeed = Math.min(hSpeed + friction, 0)
                        }
                    }
                }


                 // 应用水平移动
                 character.x = Math.max(0, Math.min(character.x + hSpeed, containerWidth - width))

                 // 处理跳跃长按加速（按住K持续增加跳跃力）
                 if (isJumpHeld && verticalSpeed < 0) {
                     verticalSpeed += jumpHoldAcceleration
                 }


                 verticalSpeed += gravity
                 character.y += verticalSpeed
                 // 碰撞处理 - 改为分别检查水平和垂直
                      isOnGround = false; // 重置地面状态

                      handleVerticalCollision(oldY);
                      handleHorizontalCollision(oldX);

                      // 边界检查和屏幕底部碰撞
                      if (character.y + character.height >= containerHeight) {
                          character.y = containerHeight - character.height
                          verticalSpeed = 0
                          isOnGround = true
                      }

                      // 更新跳跃状态
                      if (isOnGround) {
                          canJump = true
                      }

                      // 确保不会超出屏幕边界
                      character.x = Math.max(0, Math.min(character.x, containerWidth - character.width))
                      character.y = Math.max(0, Math.min(character.y, containerHeight - character.height))
                  }
              }

              // 垂直碰撞检测函数
    function handleVerticalCollision(oldY) {
        isOnGround = false; // 重置地面状态
        var collisionOccurred = false;

        for (var i = 0; i < grounds.length; i++) {
            var ground = grounds[i]
            if (!ground.visible || ground.opacity === 0) continue

            if (collidesWith(ground)) {
                collisionOccurred = true;

                // 计算碰撞深度
                var bottomCollision = ground.y - (character.y + character.height);
                var topCollision = (character.y) - (ground.y + ground.height);
                var rightCollision = (character.x + character.width) - ground.x;
                var leftCollision = ground.x + ground.width - character.x;

                // 确定最小碰撞深度方向
                var minOverlap = Math.min(
                    Math.abs(bottomCollision),
                    Math.abs(topCollision),
                    Math.abs(rightCollision),
                    Math.abs(leftCollision)
                );

                // 根据最小重叠方向解决碰撞
                if (minOverlap === Math.abs(bottomCollision)) {
                    // 从底部碰撞（站在平台上）
                    character.y = ground.y - character.height;
                    verticalSpeed = 0;
                    isOnGround = true;
                    return; // 只处理一个碰撞
                } else if (minOverlap === Math.abs(topCollision)) {
                    // 从顶部碰撞（撞到天花板）
                    character.y = ground.y + ground.height;
                    verticalSpeed = 0;
                    return; // 只处理一个碰撞
                }
            }
        }
    }

              // 水平碰撞检测函数
    function handleHorizontalCollision(oldX) {
        for (var i = 0; i < grounds.length; i++)
        {
            var ground = grounds[i]
            if (!ground.visible || ground.opacity === 0) continue

            if (collidesWith(ground)) {
                // 计算碰撞深度
                var rightCollision = (character.x + character.width) - ground.x;
                var leftCollision = (ground.x + ground.width) - character.x;

                // 确定最小碰撞深度方向
                if (rightCollision < leftCollision) {
                    // 右侧碰撞（碰到左边的物体）
                    character.x = ground.x - character.width;
                } else {
                    // 左侧碰撞（碰到右边的物体）
                    character.x = ground.x + ground.width;
                }
                hSpeed = 0;
                return; // 只处理一个碰撞
            }
        }
    }

              // 碰撞检测函数
              function collidesWith(ground) {
                  return character.x < ground.x + ground.width &&
                         character.x + character.width > ground.x &&
                         character.y < ground.y + ground.height &&
                         character.y + character.height > ground.y;
              }

              Component.onCompleted: {
                  visual.forceActiveFocus()
              }
}

