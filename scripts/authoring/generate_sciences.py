import json
import random
from deep_translator import GoogleTranslator

qs = [
    {"q": "What is the chemical symbol for water?", "opt": ["H2O", "O2", "CO2", "HO"], "ans": "H2O", "cat": "كيمياء"},
    {"q": "What planet is known as the Red Planet?", "opt": ["Mars", "Venus", "Jupiter", "Saturn"], "ans": "Mars", "cat": "فلك"},
    {"q": "What is the powerhouse of the cell?", "opt": ["Mitochondria", "Nucleus", "Ribosome", "Endoplasmic Reticulum"], "ans": "Mitochondria", "cat": "أحياء"},
    {"q": "What gas do plants absorb during photosynthesis?", "opt": ["Carbon Dioxide", "Oxygen", "Nitrogen", "Hydrogen"], "ans": "Carbon Dioxide", "cat": "أحياء"},
    {"q": "Which scientist proposed the theory of relativity?", "opt": ["Albert Einstein", "Isaac Newton", "Nikola Tesla", "Marie Curie"], "ans": "Albert Einstein", "cat": "فيزياء"},
    {"q": "What is the hardest natural substance on Earth?", "opt": ["Diamond", "Gold", "Iron", "Quartz"], "ans": "Diamond", "cat": "جيولوجيا"},
    {"q": "How many bones are in the adult human body?", "opt": ["206", "201", "210", "196"], "ans": "206", "cat": "تشريح"},
    {"q": "What force keeps us on the ground?", "opt": ["Gravity", "Magnetism", "Friction", "Inertia"], "ans": "Gravity", "cat": "فيزياء"},
    {"q": "What is the closest star to Earth?", "opt": ["The Sun", "Proxima Centauri", "Sirius", "Alpha Centauri"], "ans": "The Sun", "cat": "فلك"},
    {"q": "At what temperature does water boil? (Celsius)", "opt": ["100", "50", "150", "200"], "ans": "100", "cat": "فيزياء"},
    {"q": "What is the main organ of the cardiovascular system?", "opt": ["Heart", "Lungs", "Brain", "Liver"], "ans": "Heart", "cat": "أحياء"},
    {"q": "What consists of protons, neutrons, and electrons?", "opt": ["Atom", "Molecule", "Cell", "Tissue"], "ans": "Atom", "cat": "كيمياء"},
    {"q": "Which organ is responsible for pumping blood?", "opt": ["Heart", "Lungs", "Kidneys", "Liver"], "ans": "Heart", "cat": "تشريح"},
    {"q": "What is the largest ocean on Earth?", "opt": ["Pacific Ocean", "Atlantic Ocean", "Indian Ocean", "Arctic Ocean"], "ans": "Pacific Ocean", "cat": "جغرافيا حيوي"},
    {"q": "What type of animal is a frog?", "opt": ["Amphibian", "Reptile", "Mammal", "Bird"], "ans": "Amphibian", "cat": "أحياء"},
    {"q": "What element is denoted by 'O' on the periodic table?", "opt": ["Oxygen", "Osmium", "Oganesson", "Gold"], "ans": "Oxygen", "cat": "كيمياء"},
    {"q": "What is the center of an atom called?", "opt": ["Nucleus", "Proton", "Electron", "Neutron"], "ans": "Nucleus", "cat": "فيزياء"},
    {"q": "Which is the largest planet in our solar system?", "opt": ["Jupiter", "Saturn", "Earth", "Neptune"], "ans": "Jupiter", "cat": "فلك"},
    {"q": "What is the most abundant gas in Earth's atmosphere?", "opt": ["Nitrogen", "Oxygen", "Carbon Dioxide", "Argon"], "ans": "Nitrogen", "cat": "كيمياء"},
    {"q": "Who invented the telephone?", "opt": ["Alexander Graham Bell", "Thomas Edison", "Nikola Tesla", "Guglielmo Marconi"], "ans": "Alexander Graham Bell", "cat": "اختراعات"},
    {"q": "What part of the plant conducts photosynthesis?", "opt": ["Leaf", "Root", "Stem", "Flower"], "ans": "Leaf", "cat": "أحياء"},
    {"q": "What is the speed of light in a vacuum? (approx)", "opt": ["300,000 km/s", "150,000 km/s", "1,000 km/s", "400,000 km/s"], "ans": "300,000 km/s", "cat": "فيزياء"},
    {"q": "What is the largest organ of the human body?", "opt": ["Skin", "Brain", "Liver", "Heart"], "ans": "Skin", "cat": "تشريح"},
    {"q": "What do bees collect to make honey?", "opt": ["Nectar", "Pollen", "Water", "Honeydew"], "ans": "Nectar", "cat": "أحياء"},
    {"q": "How many arms does an octopus have?", "opt": ["8", "6", "10", "12"], "ans": "8", "cat": "أحياء"},
    {"q": "What do we call a scientist who studies stars?", "opt": ["Astronomer", "Astrologer", "Geologist", "Biologist"], "ans": "Astronomer", "cat": "فلك"},
    {"q": "Which planet is famous for its rings?", "opt": ["Saturn", "Jupiter", "Uranus", "Neptune"], "ans": "Saturn", "cat": "فلك"},
    {"q": "What is the chemical symbol for Gold?", "opt": ["Au", "Ag", "Gd", "Go"], "ans": "Au", "cat": "كيمياء"},
    {"q": "What animal is known to be the fastest land mammal?", "opt": ["Cheetah", "Lion", "Leopard", "Horse"], "ans": "Cheetah", "cat": "أحياء"},
    {"q": "What is H2O more commonly known as?", "opt": ["Water", "Salt", "Sugar", "Air"], "ans": "Water", "cat": "كيمياء"},
    {"q": "What causes the tides on Earth?", "opt": ["The Moon's Gravity", "The Sun's Gravity", "Earth's Rotation", "Wind"], "ans": "The Moon's Gravity", "cat": "فيزياء"},
    {"q": "Which human organ filters blood and produces urine?", "opt": ["Kidneys", "Liver", "Stomach", "Heart"], "ans": "Kidneys", "cat": "تشريح"},
    {"q": "What is the main energy source for life on Earth?", "opt": ["The Sun", "Water", "Oxygen", "Geothermal Energy"], "ans": "The Sun", "cat": "فلك"},
    {"q": "Who discovered penicillin?", "opt": ["Alexander Fleming", "Louis Pasteur", "Marie Curie", "Robert Koch"], "ans": "Alexander Fleming", "cat": "طب"},
    {"q": "What is the largest mammal in the world?", "opt": ["Blue Whale", "Elephant", "Giraffe", "Shark"], "ans": "Blue Whale", "cat": "أحياء"},
    {"q": "What do you call a baby kangaroo?", "opt": ["Joey", "Cub", "Pup", "Calf"], "ans": "Joey", "cat": "أحياء"},
    {"q": "How many inner planets are in the solar system?", "opt": ["4", "3", "5", "6"], "ans": "4", "cat": "فلك"},
    {"q": "What is the chemical symbol for Iron?", "opt": ["Fe", "Ir", "In", "I"], "ans": "Fe", "cat": "كيمياء"},
    {"q": "What is the process of a liquid turning into gas called?", "opt": ["Evaporation", "Condensation", "Sublimation", "Melting"], "ans": "Evaporation", "cat": "فيزياء"},
    {"q": "Which vitamin is heavily associated with sunlight?", "opt": ["Vitamin D", "Vitamin C", "Vitamin A", "Vitamin B12"], "ans": "Vitamin D", "cat": "طب"},
    {"q": "What protects the Earth from harmful solar radiation?", "opt": ["Ozone Layer", "Magnetic Field", "Clouds", "Nitrogen"], "ans": "Ozone Layer", "cat": "جغرافيا حيوي"},
    {"q": "What instrument is used to measure earthquakes?", "opt": ["Seismograph", "Barometer", "Thermometer", "Hygrometer"], "ans": "Seismograph", "cat": "جيولوجيا"},
    {"q": "What galaxy is Earth located in?", "opt": ["Milky Way", "Andromeda", "Sombrero", "Whirlpool"], "ans": "Milky Way", "cat": "فلك"},
    {"q": "What is the study of weather called?", "opt": ["Meteorology", "Geology", "Biology", "Ecology"], "ans": "Meteorology", "cat": "علوم البيئة"},
    {"q": "Which blood type is the universal donor?", "opt": ["O Negative", "AB Positive", "A Positive", "B Negative"], "ans": "O Negative", "cat": "طب"},
    {"q": "Which gas makes up bubbles in sodas?", "opt": ["Carbon Dioxide", "Oxygen", "Helium", "Nitrogen"], "ans": "Carbon Dioxide", "cat": "كيمياء"},
    {"q": "What holds atoms together in a molecule?", "opt": ["Chemical Bonds", "Gravity", "Magnetism", "Friction"], "ans": "Chemical Bonds", "cat": "فيزياء"},
    {"q": "What part of the brain controls balance?", "opt": ["Cerebellum", "Cerebrum", "Brainstem", "Thalamus"], "ans": "Cerebellum", "cat": "تشريح"},
    {"q": "Who is known as the father of modern physics?", "opt": ["Albert Einstein", "Isaac Newton", "Galileo Galilei", "Niels Bohr"], "ans": "Albert Einstein", "cat": "فيزياء"},
    {"q": "Which element makes up graphite in pencils?", "opt": ["Carbon", "Lead", "Silver", "Iron"], "ans": "Carbon", "cat": "كيمياء"}
]

def map_translates():
    print("Generating Sciences DB...")
    output = []
    translator = GoogleTranslator(source='en', target='ar')
    
    for i, item in enumerate(qs):
        en_q = item['q']
        ar_q = translator.translate(en_q)
        
        ar_opts = []
        for opt in item['opt']:
            if opt.isdigit() or opt == "H2O" or opt == "Au" or opt == "Fe":
                ar_opts.append(opt)
            else:
                ar_opts.append(translator.translate(opt))
                
        en_ans = item['ans']
        
        if en_ans.isdigit() or en_ans == "H2O" or en_ans == "Au" or en_ans == "Fe":
            ar_ans = en_ans
        else:
            ar_ans = translator.translate(en_ans)
            
        diff = 1 if i < 15 else (2 if i < 35 else 3)
            
        output.append({
            "id": f"sc_q{i}",
            "question": en_q,
            "question_ar": ar_q,
            "options": item['opt'],
            "options_ar": ar_opts,
            "correct_answer": en_ans,
            "correct_answer_ar": ar_ans,
            "category": item['cat'],
            "difficulty": diff
        })
        print(f"Done {i+1}/50...")
        
    with open('assets/data/sciences.json', 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    map_translates()
