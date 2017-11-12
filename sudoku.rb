class Board
  
  attr_reader :constraint_groups

  def initialize
    cells = (0...(9*9)).to_a
    @constraint_groups = []
    (0...9).each do |x|
      @constraint_groups << cells.select { |y| cells.index(y) >= (x*9) && cells.index(y) < (x*9)+9 }
      @constraint_groups << cells.select { |y| (cells.index(y) + x) % 9 == 0 }
    end
    (0...3).each do |x|
      (0...3).each do |y|
        t = y*3 + x*27
        @constraint_groups << (t..t+2).map { |z| [z, z+9, z+18] }.flatten.map { |z| cells[z] } 
      end
    end
  end

  def constraints_for(x, y)
    cell = (x*9)+y
    @constraint_groups.select { |z| z.include?(cell) }.flatten.select { |z| z != cell }.uniq
  end

  def iterate(solution)
    if solution.viable?
      target = solution.min
      if !target
        p solution.to_s
        exit
      else
        target[:cell].each do |pot|
          new_solution = solution.set(target[:coords][0], target[:coords][1], pot, self)
          iterate(new_solution)
        end
      end
    end
  end

end

class DeadEnd
  def viable?
    false
  end
end

class Solution

  def initialize(cells = nil)
    @cells = cells || (0...(9*9)).map { |x| (1..9).to_a }
  end

  def set(x, y, value, board)
    cells = @cells.map { |c| c.clone }
    cells[(x*9)+y] = [value]
    board.constraints_for(x, y).each do |z|
      cells[z] = cells[z].select { |h| h != value }
    end
    board.constraint_groups.each do |cg|
      if cg.map { |z| cells[z] }.select { |z| z.count == 1 }.group_by { |z| z }.values.map { |z| z.count }.any? { |z| z > 1 }
        return DeadEnd.new
      end
    end
    Solution.new(cells)
  end

  def min
    target = @cells.select { |x| x.count > 1 }.sort_by { |x| x.count }.first
    return target && { :coords => index_to_xy(@cells.index(target)), :cell => target } 
  end

  def viable?
    @cells.all? { |x| x.count > 0 }
  end

  def index_to_xy(index)
    x = index / 9
    y = index % 9
    return [x,y]
  end

  def to_s
    (0...9).each do |x|
      (0...9).each do |y|
        t =  @cells[(x*9)+y]
        print t[0] if t.count == 1
        print "_" if t.count > 1
        print "x" if t.count == 0
      end
      print "\n"
    end
    print "\n"
  end

end

class TemplateLoader

  def self.load(filename, board)
    solution = Solution.new
    y = 0
    lines = File.readlines(filename)
    (0...9).each do |y|
      line = lines[y]
      (0...9).each do |x|
        value = char_to_numbers(line[x])
        solution = solution.set(y,x, value, board) if value
      end
    end
    solution
  end

  def self.char_to_numbers(char)
    return char.to_i if char != "_"
    return nil
  end

end

$start = Time.now
file = ARGV[0]
board = Board.new
starting_solution = TemplateLoader.load(file, board)
board.iterate(starting_solution)
