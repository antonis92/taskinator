module Taskinator
  module Definition
    class Builder

      attr_reader :process
      attr_reader :definition
      attr_reader :args

      def initialize(process, definition, args)
        @process = process
        @definition = definition
        @args = args
        @executor = Taskinator::Executor.new(@definition)
      end

      # defines a sub process of tasks which are executed sequentially
      def sequential(options={}, &block)
        raise ArgumentError, 'block' unless block_given?

        sub_process = Process.define_sequential_process_for(@definition, options)
        Builder.new(define_sub_process_task(@process, sub_process, options), @definition, @args).instance_eval(&block)
      end

      # defines a sub process of tasks which are executed concurrently
      def concurrent(complete_on=CompleteOn::Default, options={}, &block)
        raise ArgumentError, 'block' unless block_given?

        sub_process = Process.define_concurrent_process_for(@definition, complete_on, options)
        Builder.new(define_sub_process_task(@process, sub_process, options), @definition, @args).instance_eval(&block)
      end

      # dynamically defines tasks, using the given @iterator method
      # the definition will be evaluated for each yielded item
      def for_each(iterator_method, options={}, &block)
        raise ArgumentError, 'iterator_method' if iterator_method.nil?
        raise NoMethodError, iterator_method unless @executor.respond_to?(iterator_method)
        raise ArgumentError, 'block' unless block_given?

        @executor.send(iterator_method, *@args) do |*args|
          Builder.new(@process, @definition, args).instance_eval(&block)
        end
      end

      # defines a task which executes the given @method
      def task(method, options={})
        raise ArgumentError, 'method' if method.nil?
        raise NoMethodError, method unless @executor.respond_to?(method)

        define_step_task(@process, method, @args, options)
      end

      # defines a sub process task, for the given @definition
      # the definition specified must have input compatible arguments
      # to the current definition
      def sub_process(definition, options={})
        raise ArgumentError, 'definition' if definition.nil?
        raise ArgumentError, "#{definition.name} does not extend the #{Definition.name} module" unless definition.kind_of?(Definition)

        # TODO: decide whether the sub process to dynamically receive arguments

        sub_process = definition.create_process(*@args)
        Builder.new(define_sub_process_task(@process, sub_process, options), definition, @args)
      end

    private

      def define_step_task(process, method, args, options={})
        define_task(process) {
          Task.define_step_task(process, method, args, options)
        }
      end

      def define_sub_process_task(process, sub_process, options={})
        define_task(process) {
          Task.define_sub_process_task(process, sub_process, options)
        }
        sub_process
      end

      def define_task(process)
        process.tasks << task = yield
        task
      end
    end
  end
end