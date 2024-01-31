-- local Util = DAL:Ext("DariansUtilities")
local Util = DariansUtilities
Util.LinkedList = Util.LinkedList or { }
local LinkedList = Util.LinkedList

local log = Util.log

function LinkedList:New()
	local o = { }
	setmetatable(o, self)
	self.__index = self

	o.first = nil
	o.last = nil
	o.size = 0

	return o
end

function LinkedList:PushFirst(value)
	local node = { value = value }
	self.size = self.size + 1

	if not self.first then
		self.first = node
		self.last = node
	else
		self.first.prev = node
		node.next = self.first
		self.first = node
	end
end

function LinkedList:PushLast(value)
	local node = { value = value }
	self.size = self.size + 1

	if not self.last then
		self.first = node
		self.last = node
	else
		self.last.next = node
		node.prev = self.last
		self.last = node
	end
end

function LinkedList:PopFirst()
	if not self.first then return nil end

	self.size = self.size - 1
	local value = self.first.value

	if self.first.next then
		self.first = self.first.next
		self.first.prev = nil
	else
		self.first = nil
		self.last = nil
	end

	return value
end

function LinkedList:PopLast()
	if not self.last then return nil end

	self.size = self.size - 1
	local value = self.last.value

	if self.last.prev then
		self.last = self.last.prev
		self.last.next = nil
	else
		self.first = nil
		self.last = nil
	end

	return value
end

function LinkedList:PeekFirst()
	if not self.first then return nil end

	return self.first.value
end

function LinkedList:PeekLast()
	if not self.last then return nil end

	return self.last.value
end

-- ITERATION

function LinkedList:ForEach(callback)
	local node = self.first

	while node do
		callback(node.value)
		node = node.next
	end
end

function LinkedList:ForEachReverse(callback)
	local node = self.last

	while node do
		callback(node.value)
		node = node.prev
	end
end

-- LIST POINTERS

LinkedList.Pointer = { }

function LinkedList:Iter()
	return LinkedList.Pointer.new(self)
end

--[[
    Creates a new Pointer object for the passed list
    Pointers can exist in meta states, where the next
      prev states do not necessarily have to conform
      to the standard structure of a doubly-linked list
    This pointer starts in a meta wrap position, next() 
      puts the pointer and prev() puts the pointer at
      the end of the list. This makes iteration in either
      direction incredibly simple and intuitive.
--]]
function LinkedList.Pointer.new(list)
	local pointer = { }
	setmetatable(pointer, LinkedList.Pointer)
	LinkedList.Pointer.__index = LinkedList.Pointer

	pointer.list = list
	pointer.node = {
		next = list.first,
		prev = list.last,
		meta = true,
	}

	return pointer
end

function LinkedList.Pointer:Reset()
	self.node = {
		next = self.list.first,
		prev = self.list.prev,
		meta = true,
	}
end

function LinkedList.Pointer:HasNext()
	return self.node.next ~= nil
end

function LinkedList.Pointer:HasPrev()
	return self.node.prev ~= nil
end

function LinkedList.Pointer:Next()
	self.node = self.node.next
	return self.node.value
end

function LinkedList.Pointer:Prev()
	self.node = self.node.prev
	return self.node.prev
end

function LinkedList.Pointer:Remove()
	if self.node.meta then error("Can't remove - No node selected") end

	if self.node.prev then
		if self.node.next then
			self.node.prev.next = self.node.next
			self.node.next.prev = self.node.prev
		else
			self.node.prev.next = nil
			self.list.last = self.node.prev
		end
	else
		if self.node.next then
			self.node.next.prev = nil
			self.list.first = self.node.next
		else
			self.list.first = nil
			self.list.last = nil
		end
	end

	self.node = {
		next = self.node.next,
		prev = self.node.prev,
		meta = true,
	}
end

function LinkedList.Pointer:Update(value)
	if self.node.meta then error("Can't update - No node selected") end

	self.node.value = value
end

function LinkedList.Pointer:InsertNext(value)
	if self.node.meta then error("Can't insertNext - No node selected") end

	local node = { value = value }
	self.node.next = node
	node.prev = self.node

	if self.node.next then
		node.next = self.node.next 
		self.node.next.prev = node
	else
		self.list.last = node
	end
end

function LinkedList.Pointer:InsertPrev(value)
	if self.node.meta then error("Can't insertPrev - No node selected") end

	local node = { value = value }
	self.node.prev = node
	node.next = self.node

	if self.node.prev then
		node.prev = self.node.prev
		self.node.prev.next = node
	else
		self.list.first = node
	end
end