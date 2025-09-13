type HeavyHitter struct {
  identifier string
  frequency int
}

func topK(events []String, int k) (HeavyHitter) {
  frequencyTable := make(map[string]int)
  for _, event := range events {
    value := frequencyTable[event]
    if value == 0 {
      frequencyTable[event] = 1
    } else {
      frequencyTable[event] = value + 1
    }
  }

  pq = make(PriorityQueue, k)
  i := 0
  for key, element := range frequencyTable {
    pq[i++] = &HeavyHitter{
      identifier: key,
      frequency: element
    }
    if pq.Len() > k {
      pq.Pop(&pq).(*HeavyHitter)
    }
  }

  /*   
   * Write the heap contents to your destination.  
   * Here we just return them in an array.  
   */
  var result [k]HeavyHitter
  i := 0
  for pq.Len() > 0 {
    result[i++] = pq.Pop(&pq).(*HeavyHitter)
  }
  return result
}

