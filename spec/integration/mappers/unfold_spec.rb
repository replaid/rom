require 'spec_helper'
require 'rom/memory'

describe 'Mapper definition DSL' do
  let(:setup) { ROM.setup(:memory) }
  let(:rom)   { ROM.finalize.env   }

  before do
    setup.relation(:users)

    users = setup.default.dataset(:users)

    users.insert(name: 'Joe',  roles: ['admin', 'user', 'user', nil])
    users.insert(name: 'Jane', roles: 'user')
    users.insert(name: 'John')
  end

  describe 'unfold' do
    let(:mapped_users) { rom.relation(:users).as(:users).to_a }

    it 'splits the attribute' do
      setup.mappers do
        define(:users) { unfold :roles }
      end

      expect(mapped_users).to eql [
        { name: 'Joe',  roles: 'admin' },
        { name: 'Joe',  roles: 'user'  },
        { name: 'Joe',  roles: 'user'  },
        { name: 'Joe',  roles: nil     },
        { name: 'Jane', roles: 'user'  },
        { name: 'John'                 }
      ]
    end

    it 'renames unfolded attribute when necessary' do
      setup.mappers do
        define(:users) { unfold :role, from: :roles }
      end

      expect(mapped_users).to eql [
        { name: 'Joe',  role: 'admin' },
        { name: 'Joe',  role: 'user'  },
        { name: 'Joe',  role: 'user'  },
        { name: 'Joe',  role: nil     },
        { name: 'Jane', role: 'user'  },
        { name: 'John'                }
      ]
    end

    it 'rewrites the existing attribute' do
      setup.mappers do
        define(:users) { unfold :name, from: :roles }
      end

      expect(mapped_users).to eql [
        { name: 'admin' },
        { name: 'user'  },
        { name: 'user'  },
        { name: nil     },
        { name: 'user'  },
        {}
      ]
    end

    it 'ignores the absent attribute' do
      setup.mappers do
        define(:users) { unfold :foo, from: :absent }
      end

      expect(mapped_users).to eql [
        { name: 'Joe',  roles: ['admin', 'user', 'user', nil] },
        { name: 'Jane', roles: 'user' },
        { name: 'John' }
      ]
    end

    it 'accepts block' do
      setup.mappers do
        define(:users) { unfold(:role, from: :roles) {} }
      end

      expect(mapped_users).to eql [
        { name: 'Joe',  role: 'admin' },
        { name: 'Joe',  role: 'user'  },
        { name: 'Joe',  role: 'user'  },
        { name: 'Joe',  role: nil     },
        { name: 'Jane', role: 'user'  },
        { name: 'John'                }
      ]
    end
  end
end
