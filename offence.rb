require 'dxruby'
require_relative 'ev3/ev3'
require_relative 'ev3/commands/load_commands'

LEFT_MOTOR = "C"
RIGHT_MOTOR = "B"
ARM_MOTOR="A"
DISTANCE_SENSOR = "4"
COLOR_SENSOR = "3"
GYRO_SENSOR = "1"
PORT = "COM3"
MOTOR_SPEED = 30

begin
  puts "starting..."
  font = Font.new(32)
  brick = EV3::Brick.new(EV3::Connections::Bluetooth.new(PORT))
  brick.connect
  puts "connected..."
  motors = [LEFT_MOTOR, RIGHT_MOTOR]
  #モータのタコメータを初期化
  brick.reset(*motors)

  puts ("start")

  brick.run_forward(ARM_MOTOR)
  brick.step_velocity(7, 90, 90, ARM_MOTOR)
  brick.motor_ready(ARM_MOTOR)
  brick.motor_ready(RIGHT_MOTOR)

  puts ("arm")

  #距離を表示
  Window.loop do
    brick.start(MOTOR_SPEED, *motors)
    d = brick.get_sensor(DISTANCE_SENSOR, 0)
    Window.draw_font(100, 200, "#{d.to_i}cm", font)

    #終了処理
    break if Input.keyDown?(K_SPACE)

    brick.get_sensor(GYRO_SENSOR, 0)

    #茶色を感知
    if brick.get_sensor(COLOR_SENSOR, 2) == 7
      #ストップ
      brick.stop(false, *motors)
      degree0 = brick.get_sensor(GYRO_SENSOR, 0)
      brick.start(MOTOR_SPEED, RIGHT_MOTOR)
      loop do
        degree = brick.get_sensor(GYRO_SENSOR, 0)
        p degree0-degree
        break if degree-degree0 <= -180
      end
      brick.stop(false, *motors)
      brick.run_forward(*motors)
    end

    #距離センサの値で場合分け
    #前進する
    if d > 20.5
      brick.stop(false,ARM_MOTOR) if brick.get_sensor(COLOR_SENSOR, 2) == 7

    #壁の前
    elsif d <= 20.5
      #ストップ
      brick.stop(false, *motors)

      #アームを上げる
      brick.reverse_polarity(ARM_MOTOR)
      brick.step_velocity(7, 90, 90, ARM_MOTOR)
      brick.motor_ready(ARM_MOTOR)
      brick.motor_ready(RIGHT_MOTOR)

      #アームを下げる
      brick.run_forward(ARM_MOTOR)
      brick.step_velocity(7, 90, 90, ARM_MOTOR)
      brick.motor_ready(ARM_MOTOR)
      brick.motor_ready(RIGHT_MOTOR)

      ##左に曲がる
      degree0 = brick.get_sensor(GYRO_SENSOR, 0)
      brick.start(MOTOR_SPEED, RIGHT_MOTOR)
        loop do
          degree = brick.get_sensor(GYRO_SENSOR, 0)
          p degree0-degree
        break if degree-degree0 <= -180
        end
      brick.stop(false, *motors)
      brick.run_forward(*motors)
    end
  end

  #センサー情報の更新
  def update
    @distance = @brick.get_sensor(DISTANCE_SENSOR, 0)
  end

  rescue
    p $!

  #終了処理は必ず実行する
  ensure
    puts "closing..."
    brick.stop(false, *motors)
    brick.clear_all
    brick.disconnect
    puts "finished..."
end