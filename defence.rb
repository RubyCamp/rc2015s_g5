require 'dxruby'
require_relative 'ev3/ev3'

class Carrier
  ARM_R_MOTOR = "A"
  ARM_L_MOTOR = "D"
  BACK_MOTOR = "B"
  PORT = "COM3"
  ARM_SPEED = 15
  TATE_SPEED = 10

  attr_reader :distance

  def initialize
    @brick = EV3::Brick.new(EV3::Connections::Bluetooth.new(PORT))
    @brick.connect
    @busy = false
    @state = :closed_arm
    p "velo"
    #@brick.step_velocity(10, 40, 50, BACK_MOTOR)
    p "city"
  end

  # アームを上げる
  def close_arm(speed=ARM_SPEED)
    return if @state == :closed_arm
    operate do
      p "raise arm!"
      @brick.reverse_polarity(ARM_R_MOTOR)
      @brick.step_velocity(20, 90, 10, ARM_R_MOTOR)
      @brick.step_velocity(20, 85, 10, ARM_L_MOTOR)
      @brick.motor_ready(ARM_L_MOTOR, ARM_R_MOTOR)
      @brick.run_forward(ARM_R_MOTOR, ARM_L_MOTOR)
      @state = :closed_arm
    end
  end

  # アームを下げる
  def open_arm(speed=ARM_SPEED)
    return if @state == :opened_arm
    operate do
      p "down arm!"
      @brick.reverse_polarity(ARM_L_MOTOR)
      @brick.step_velocity(5, 90, 10, ARM_R_MOTOR)
      @brick.step_velocity(5, 85, 10, ARM_L_MOTOR)
      @brick.motor_ready(ARM_L_MOTOR, ARM_R_MOTOR)
      @brick.run_forward(ARM_R_MOTOR, ARM_L_MOTOR)
      @state = :opened_arm
    end
  end

  #盾をブンブンする
  def bunbun_arm(speed=TATE_SPEED)
    operate do
    p "bunbun arm"
    @brick.reverse_polarity(BACK_MOTOR)
    @brick.step_velocity(10, 50, 10, BACK_MOTOR)
    #@brick.motor_redy(BACK_MOTOR)
    end
  end

  #盾をひゅんひゅんする
  def hyunhyun_arm(speed=TATE_SPEED)
    operate do
      p "hyunhyun arm"
      @brick.step_velocity(10, 200, 30, BACK_MOTOR)
      # @brick.motor_redy(BACK_MOTOR)
    end
  end

  # 動きを止める
  def stop
    @brick.stop(true, *arm_motors)
    @busy = false
  end

  # ある動作中は別の動作を受け付けないようにする
  def operate
     unless @busy
      @busy = true
      yield(@brick)
      stop
    end
  end

  #アームをぱたぱたする
  def run
    close_arm
    open_arm
  end

  #盾をブンブンする
  def tate
    bunbun_arm
    @brick.reverse_polarity(BACK_MOTOR)
    hyunhyun_arm
  end

  # 終了処理
  def close
    @brick.stop(true, *all_motors)
    close_arm
    @brick.clear_all
    @brick.disconnect
  end

  # "～_MOTOR" という名前の定数すべての値を要素とする配列を返す
  def all_motors
     @all_motors ||= self.class.constants.grep(/_MOTOR\z/).map{|c| self.class.const_get(c) }
  end

  def arm_motors
     @arm_motors ||= self.class.constants.grep(/\AARM_.*_MOTOR\z/).map{|c| self.class.const_get(c) }
  end
end

begin
  puts "starting..."
  font = Font.new(32)
  carrier = Carrier.new
  #tate = tate.new
  puts "connected..."

  Window.loop do
    if Input.keyDown?(K_SPACE)
      break
    end
    carrier.run
    carrier.tate
    p "tate"
  end
rescue
  p $!
  $!.backtrace.each{|trace| puts trace}
# 終了処理は必ず実行する
ensure
  puts "closing..."
  carrier.close
  puts "finished..."
end
